[CmdletBinding()]
param(
    [string]$EventName = 'TaskTimeout',

    [string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot 'logs\screenshots'
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$safeEventName = [regex]::Replace($EventName, '[^A-Za-z0-9_-]', '_')
$fileName = "{0}_{1}.png" -f (Get-Date -Format 'yyyyMMdd_HHmmss_fff'), $safeEventName
$filePath = Join-Path $OutputDirectory $fileName

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$screenBounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
if ($screenBounds.Width -le 0 -or $screenBounds.Height -le 0) {
    throw '无法获取屏幕尺寸。'
}

$bitmap = New-Object System.Drawing.Bitmap -ArgumentList $screenBounds.Width, $screenBounds.Height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
    $graphics.CopyFromScreen(
        $screenBounds.Left,
        $screenBounds.Top,
        0,
        0,
        $screenBounds.Size
    )
    $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $filePath
} finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}
