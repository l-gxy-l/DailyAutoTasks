[CmdletBinding()]
param(
    [string]$EventName = 'StarRailTimeout',

    [ValidateRange(0, 86400)]
    [int]$WaitSeconds = 1800,

    [int]$TerminationExitCode = 0,

    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $projectRoot 'config\mail.ini'
}
$logPath = Join-Path $projectRoot 'logs\通知日志.log'

function Write-NotificationLog {
    param([string]$Message)

    $logDirectory = Split-Path -Parent $logPath
    if (-not (Test-Path -LiteralPath $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $logPath -Encoding UTF8 -Value "[$timestamp] $Message"
}

function Read-KeyValueFile {
    param([string]$Path)

    $values = @{}
    foreach ($rawLine in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line.StartsWith(';') -or $line.StartsWith('#') -or $line.StartsWith('[')) {
            continue
        }

        $separatorIndex = $line.IndexOf('=')
        if ($separatorIndex -le 0) {
            continue
        }

        $key = $line.Substring(0, $separatorIndex).Trim().ToLowerInvariant()
        $value = $line.Substring($separatorIndex + 1).Trim()

        if ($value.Length -ge 2) {
            $first = $value[0]
            $last = $value[$value.Length - 1]
            if (($first -eq [char]34 -or $first -eq [char]39) -and $first -eq $last) {
                $value = $value.Substring(1, $value.Length - 2)
            }
        }

        $values[$key] = $value
    }

    return $values
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    Write-NotificationLog 'SKIPPED | 邮件配置文件不存在，请参考 config\mail.txt 创建 config\mail.ini'
    exit 3
}

try {
    $settings = Read-KeyValueFile -Path $ConfigPath
} catch {
    Write-NotificationLog "FAILED | 无法读取邮件配置：$($_.Exception.Message)"
    exit 3
}

$enabled = $settings.ContainsKey('enabled') -and $settings['enabled'].ToLowerInvariant() -in @('1', 'true', 'yes', 'on')
if (-not $enabled) {
    Write-NotificationLog "SKIPPED | Event=$EventName；邮件通知未启用"
    exit 3
}

$requiredKeys = @('smtp_server', 'smtp_port', 'from', 'to', 'user', 'auth_code')
$missingKeys = @($requiredKeys | Where-Object {
    -not $settings.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($settings[$_])
})
if ($missingKeys.Count -gt 0) {
    Write-NotificationLog "FAILED | Event=$EventName；邮件配置缺少字段：$($missingKeys -join ', ')"
    exit 3
}

$placeholderAuthCodes = @('请填写QQ邮箱生成的SMTP授权码', '你的QQ邮箱SMTP授权码')
if ($settings['auth_code'] -in $placeholderAuthCodes) {
    Write-NotificationLog "FAILED | Event=$EventName；请将 mail.ini 中的 auth_code 替换为 QQ 邮箱 SMTP 授权码"
    exit 3
}

$smtpPort = 0
if (-not [int]::TryParse($settings['smtp_port'], [ref]$smtpPort)) {
    Write-NotificationLog "FAILED | Event=$EventName；smtp_port 不是有效端口"
    exit 3
}

$machineName = [Environment]::MachineName
$eventTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$eventDefinitions = @{
    StarRailTimeout = @{
        GameName = '崩坏：星穹铁道'
        ProcessName = 'StarRail.exe'
    }
    YuanShenTimeout = @{
        GameName = '原神'
        ProcessName = 'YuanShen.exe'
    }
    FOSTimeout = @{
        GameName = '战双帕弥什'
        ProcessName = 'FOS.exe'
    }
    EnFTimeout = @{
        GameName = '明日方舟：终末地'
        ProcessName = 'Endfield.exe'
    }
}

if ($EventName -eq 'Test') {
    $subject = "[DailyAutoTasks][$machineName] 邮件通知测试"
    $body = @"
这是一封 DailyAutoTasks 邮件通知测试。

主机：$machineName
发送时间：$eventTime

如果你收到这封邮件，说明 QQ 邮箱 SMTP 通知配置可用。
"@
} elseif ($eventDefinitions.ContainsKey($EventName)) {
    $eventInfo = $eventDefinitions[$EventName]
    $subject = "[DailyAutoTasks][$machineName] $($eventInfo.GameName)等待超时"
    $body = @"
DailyAutoTasks 检测到 $($eventInfo.ProcessName) 等待超时。

任务：$($eventInfo.GameName)
主机：$machineName
检测时间：$eventTime
等待时长：$WaitSeconds 秒
处理结果：已执行强制结束
taskkill 返回码：$TerminationExitCode（0 通常表示成功）

请结合 logs\主脚本运行日志及对应任务日志检查异常原因。
"@
} else {
    $subject = "[DailyAutoTasks][$machineName] 任务等待超时"
    $body = @"
DailyAutoTasks 检测到任务等待超时。

事件：$EventName
主机：$machineName
检测时间：$eventTime
等待时长：$WaitSeconds 秒
处理结果：已执行强制结束
taskkill 返回码：$TerminationExitCode（0 通常表示成功）

请结合 logs\主脚本运行日志及对应任务日志检查异常原因。
"@
}

$message = New-Object System.Net.Mail.MailMessage
$client = $null
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $message.From = New-Object System.Net.Mail.MailAddress($settings['from'])
    $message.To.Add($settings['to'])
    $message.Subject = $subject
    $message.SubjectEncoding = [Text.Encoding]::UTF8
    $message.Body = $body
    $message.BodyEncoding = [Text.Encoding]::UTF8
    $message.IsBodyHtml = $false

    $client = New-Object System.Net.Mail.SmtpClient($settings['smtp_server'], $smtpPort)
    $client.EnableSsl = $true
    $client.Timeout = 20000
    $client.DeliveryMethod = [Net.Mail.SmtpDeliveryMethod]::Network
    $client.Credentials = New-Object System.Net.NetworkCredential($settings['user'], $settings['auth_code'])
    $client.Send($message)

    Write-NotificationLog "SENT | Event=$EventName；收件人=$($settings['to'])"
    exit 0
} catch {
    Write-NotificationLog "FAILED | Event=$EventName；$($_.Exception.Message)"
    Write-Error "发送邮件通知失败：$($_.Exception.Message)"
    exit 1
} finally {
    if ($null -ne $client) {
        $client.Dispose()
    }
    $message.Dispose()
}
