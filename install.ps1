# Cursor RTL FA - Add styles to Cursor settings
# Run: Right-click -> Run with PowerShell, or: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"
$settingsPath = "$env:APPDATA\Cursor\User\settings.json"
$snippetPath = Join-Path $PSScriptRoot "settings-snippet.json"

if (-not (Test-Path $snippetPath)) {
    Write-Host "Error: settings-snippet.json not found next to this script." -ForegroundColor Red
    exit 1
}

$snippetJson = Get-Content $snippetPath -Raw -Encoding UTF8
$snippet = $snippetJson | ConvertFrom-Json

$dir = Split-Path $settingsPath
if (-not (Test-Path $dir)) {
    Write-Host "Error: Cursor user folder not found: $dir" -ForegroundColor Red
    exit 1
}

# Create empty settings if missing
if (-not (Test-Path $settingsPath)) {
    Set-Content -Path $settingsPath -Value "{}" -Encoding UTF8
}

# Backup
$backupPath = "$settingsPath.backup." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item -Path $settingsPath -Destination $backupPath -Force
Write-Host "Backup: $backupPath" -ForegroundColor Gray

try {
    $currentJson = Get-Content $settingsPath -Raw -Encoding UTF8
    $current = $currentJson | ConvertFrom-Json
} catch {
    Write-Host "Error: Could not parse existing settings.json. Restore from: $backupPath" -ForegroundColor Red
    exit 1
}

# Merge: add or overwrite keys from snippet
$snippet.PSObject.Properties | ForEach-Object {
    $current | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
}

$resultJson = $current | ConvertTo-Json -Depth 15
Set-Content -Path $settingsPath -Value $resultJson -Encoding UTF8 -NoNewline

Write-Host "Done. RTL styles were added to Cursor settings." -ForegroundColor Green
Write-Host "In Cursor, run: Custom UI Style: Reload (Ctrl+Shift+P)" -ForegroundColor Cyan
