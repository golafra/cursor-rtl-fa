# Cursor RTL FA - Add styles to Cursor settings
# Run: Right-click -> Run with PowerShell, or: powershell -ExecutionPolicy Bypass -File install.ps1
# - نصب خودکار افزونه Custom UI Style در صورت نبود
# - ریستارت خودکار Cursor پس از اعمال تنظیمات

$ErrorActionPreference = "Stop"
$ExtensionId = "subframe7536.custom-ui-style"
$settingsPath = "$env:APPDATA\Cursor\User\settings.json"
$snippetPath = Join-Path $PSScriptRoot "settings-snippet.json"

# مسیر اجرایی Cursor (ویندوز)
function Get-CursorPath {
    $paths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    $inPath = Get-Command cursor -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }
    return $null
}

# بررسی نصب بودن افزونه و نصب در صورت نیاز
$cursorExe = Get-CursorPath
if ($cursorExe) {
    $extList = & $cursorExe --list-extensions 2>$null
    if ($extList -notmatch [regex]::Escape($ExtensionId)) {
        Write-Host "Installing extension: Custom UI Style ($ExtensionId)..." -ForegroundColor Yellow
        & $cursorExe --install-extension $ExtensionId 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Extension installed." -ForegroundColor Green
        } else {
            Write-Host "Could not install from CLI. Install manually: Extensions (Ctrl+Shift+X) -> search 'Custom UI Style'." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Extension Custom UI Style already installed." -ForegroundColor Gray
    }
} else {
    Write-Host "Cursor executable not found. Install extension manually: Extensions (Ctrl+Shift+X) -> 'Custom UI Style'." -ForegroundColor Yellow
}

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

# ریستارت خودکار Cursor تا استایل اعمال شود
if ($cursorExe) {
    Write-Host "Restarting Cursor in 3 seconds..." -ForegroundColor Cyan
    $safePath = $cursorExe -replace "'", "''"
    $restartCmd = "Start-Sleep -Seconds 3; Get-Process -Name 'Cursor' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1; Start-Process -FilePath '$safePath' -WindowStyle Normal"
    Start-Process powershell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $restartCmd -WindowStyle Hidden
    Write-Host "Cursor will close and reopen shortly. If it does not, open Cursor manually." -ForegroundColor Cyan
} else {
    Write-Host "In Cursor, run: Custom UI Style: Reload (Ctrl+Shift+P)" -ForegroundColor Cyan
}
