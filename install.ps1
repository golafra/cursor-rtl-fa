# Cursor RTL FA - Add styles to Cursor settings
# Run: Right-click -> Run with PowerShell, or: powershell -ExecutionPolicy Bypass -File install.ps1
# - نصب خودکار افزونه Custom UI Style در صورت نبود

$ErrorActionPreference = "Stop"
$ExtensionId = "subframe7536.custom-ui-style"
$settingsPath = "$env:APPDATA\Cursor\User\settings.json"
$snippetPath = Join-Path $PSScriptRoot "settings-snippet.json"

function Get-CursorCliCommand {
    $cmd = Get-Command cursor -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Get-CursorExePath {
    $paths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Invoke-NativeSafe {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $false)][string[]]$Arguments = @()
    )

    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = & $FilePath @Arguments 2>&1
        return $output
    } finally {
        $ErrorActionPreference = $prev
    }
}

$cursorCli = Get-CursorCliCommand
$cursorExe = Get-CursorExePath
if ($cursorCli) {
    $extList = (Invoke-NativeSafe -FilePath $cursorCli -Arguments @("--list-extensions")) | Where-Object { $_ -notmatch "DEP0040|punycode" }
    if ($extList -notmatch [regex]::Escape($ExtensionId)) {
        Write-Host "Installing extension: Custom UI Style ($ExtensionId)..." -ForegroundColor Yellow
        $installOutput = (Invoke-NativeSafe -FilePath $cursorCli -Arguments @("--install-extension", $ExtensionId)) | Where-Object { $_ -notmatch "DEP0040|punycode" }
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Extension installed." -ForegroundColor Green
        } else {
            if ($installOutput) { Write-Host ($installOutput -join [Environment]::NewLine) -ForegroundColor DarkGray }
            Write-Host "Could not install from CLI. Install manually: Extensions (Ctrl+Shift+X) -> search 'Custom UI Style'." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Extension Custom UI Style already installed." -ForegroundColor Gray
    }
} else {
    Write-Host "Cursor CLI command not found. Install extension manually: Extensions (Ctrl+Shift+X) -> 'Custom UI Style'." -ForegroundColor Yellow
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

if (-not (Test-Path $settingsPath)) {
    Set-Content -Path $settingsPath -Value "{}" -Encoding UTF8
}

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

$snippet.PSObject.Properties | ForEach-Object {
    $current | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
}

$resultJson = $current | ConvertTo-Json -Depth 15
Set-Content -Path $settingsPath -Value $resultJson -Encoding UTF8 -NoNewline

Write-Host "Done. RTL styles were added to Cursor settings." -ForegroundColor Green
Write-Host "Run: Custom UI Style: Reload (Ctrl+Shift+P)." -ForegroundColor Cyan

if (-not $cursorExe) {
    Write-Host "Cursor executable not found. Open Cursor manually if needed." -ForegroundColor Yellow
}
