[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateRange(1, 3650)]
    [int]$RetentionDays = 30,

    [datetime]$ReferenceDate = (Get-Date),

    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

$runLogDirectory = Join-Path $ProjectRoot 'logs\主脚本运行日志'
$configDirectory = Join-Path $ProjectRoot 'config'
$cutoffDate = $ReferenceDate.Date.AddDays(-($RetentionDays - 1))

$deletedLogCount = 0
$plannedLogCount = 0
$deletedTempCount = 0
$plannedTempCount = 0
$failedCount = 0

Write-Host "清理项目：$ProjectRoot"

$collectorNames = @('DailyTaskPerfCollector', 'DailyTaskPerfCollector_misc')
foreach ($collectorName in $collectorNames) {
    if ($PSCmdlet.ShouldProcess($collectorName, '停止系统性能日志采集器')) {
        try {
            & logman stop $collectorName 2>$null | Out-Null
            Write-Host "  [停止] 性能采集器：$collectorName"
        } catch {
            $failedCount++
            Write-Warning "停止性能采集器失败：$collectorName；$($_.Exception.Message)"
        }
    }
}

$firewallRuleNames = @('BlockMaa', 'BlockMaaEnd')
foreach ($ruleName in $firewallRuleNames) {
    if ($PSCmdlet.ShouldProcess($ruleName, '删除自动化工具防火墙规则')) {
        try {
            & netsh advfirewall firewall delete rule name=$ruleName 2>$null | Out-Null
            Write-Host "  [删除] 防火墙规则：$ruleName"
        } catch {
            $failedCount++
            Write-Warning "删除防火墙规则失败：$ruleName；$($_.Exception.Message)"
        }
    }
}

Write-Host "主脚本日志保留最近 $RetentionDays 个自然日：$($cutoffDate.ToString('yyyy-MM-dd')) 至 $($ReferenceDate.Date.ToString('yyyy-MM-dd'))"

if (Test-Path -LiteralPath $runLogDirectory -PathType Container) {
    try {
        $expiredLogs = @(
            Get-ChildItem -LiteralPath $runLogDirectory -File |
                Where-Object { $_.LastWriteTime.Date -lt $cutoffDate }
        )
    } catch {
        Write-Warning "无法读取主脚本日志目录：$($_.Exception.Message)"
        $expiredLogs = @()
        $failedCount++
    }

    foreach ($file in $expiredLogs) {
        if ($PSCmdlet.ShouldProcess($file.FullName, '删除过期主脚本日志')) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $deletedLogCount++
                Write-Host "  [删除] $($file.Name)"
            } catch {
                $failedCount++
                Write-Warning "删除失败：$($file.FullName)；$($_.Exception.Message)"
            }
        } else {
            $plannedLogCount++
        }
    }
} else {
    Write-Warning "主脚本日志目录不存在：$runLogDirectory"
}

if (Test-Path -LiteralPath $configDirectory -PathType Container) {
    try {
        $tempFiles = @(
            Get-ChildItem -LiteralPath $configDirectory -File |
                Where-Object { $_.Name.StartsWith('temp_', [System.StringComparison]::OrdinalIgnoreCase) }
        )
    } catch {
        Write-Warning "无法读取 config 目录：$($_.Exception.Message)"
        $tempFiles = @()
        $failedCount++
    }

    foreach ($file in $tempFiles) {
        if ($PSCmdlet.ShouldProcess($file.FullName, '删除 config 临时文件')) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $deletedTempCount++
                Write-Host "  [删除] temp：$($file.Name)"
            } catch {
                $failedCount++
                Write-Warning "删除失败：$($file.FullName)；$($_.Exception.Message)"
            }
        } else {
            $plannedTempCount++
        }
    }
} else {
    Write-Warning "config 目录不存在：$configDirectory"
}

Write-Host ''
if ($WhatIfPreference) {
    Write-Host "预演完成：计划删除主脚本日志 $plannedLogCount 个，计划删除 config 临时文件 $plannedTempCount 个。"
} else {
    Write-Host "清理完成：删除主脚本日志 $deletedLogCount 个，删除 config 临时文件 $deletedTempCount 个。"
}

if ($failedCount -gt 0) {
    Write-Warning "共有 $failedCount 项未能处理，请检查文件是否被占用或权限是否足够。"
    exit 1
}

exit 0
