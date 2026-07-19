# Verify markdown preview setup for cursor-rtl-fa
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$failures = @()

function Add-Failure([string]$Message) {
    $script:failures += $Message
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

$snippetPath = Join-Path $root "settings-snippet.json"
$cssPath = Join-Path $root "markdown-preview.css"
if (Test-Path $snippetPath) {
    $snippet = Get-Content $snippetPath -Raw -Encoding UTF8
    foreach ($needle in @("markdown-editor-react__richtext-content", "markdown-editor-react .ProseMirror")) {
        if ($snippet -notmatch [regex]::Escape($needle)) {
            Add-Failure "settings-snippet.json missing Cursor markdown selector: $needle"
        }
    }
} else {
    Add-Failure "settings-snippet.json not found"
}
$workspaceSettingsPath = Join-Path $root ".vscode\settings.json"
$testHtmlPath = Join-Path $root "test-preview.html"

if (-not (Test-Path $cssPath)) {
    Add-Failure "markdown-preview.css not found at $cssPath"
}

if (-not (Test-Path $workspaceSettingsPath)) {
    Add-Failure ".vscode/settings.json not found"
} else {
    $workspaceSettings = Get-Content $workspaceSettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $stylePath = $workspaceSettings."markdown.styles"[0]
    if ($stylePath -ne "markdown-preview.css") {
        Add-Failure "markdown.styles must be workspace-relative 'markdown-preview.css', got '$stylePath'"
    }

    $resolvedCss = Join-Path $root $stylePath
    if (-not (Test-Path $resolvedCss)) {
        Add-Failure "Resolved CSS path does not exist: $resolvedCss"
    }
}

$userSettingsPath = "$env:APPDATA\Cursor\User\settings.json"
if (Test-Path $userSettingsPath) {
    $userSettings = Get-Content $userSettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($userSettings.PSObject.Properties.Name -contains "markdown.styles") {
        Add-Failure "User settings still contain markdown.styles (file:// paths are ignored by Cursor preview)"
    }
    $stylesheet = $userSettings."custom-ui-style.stylesheet"
    if ($null -eq $stylesheet -or ($stylesheet | ConvertTo-Json -Depth 10) -notmatch "markdown-editor-react__richtext-content") {
        Add-Failure "User settings missing custom-ui-style markdown-editor-react selectors"
    }
}

if (Test-Path $cssPath) {
    $css = Get-Content $cssPath -Raw -Encoding UTF8
    foreach ($needle in @("direction: rtl", "IRANSans", ".markdown-body[dir=`"auto`"]")) {
        if ($css -notmatch [regex]::Escape($needle)) {
            Add-Failure "CSS missing rule marker: $needle"
        }
    }
}

$html = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <link rel="stylesheet" href="markdown-preview.css" />
  <title>Markdown Preview Test</title>
</head>
<body class="vscode-body">
  <div class="markdown-body" dir="auto">
    <h1>تست پیش‌نمایش</h1>
    <p>این متن باید راست‌چین و با فونت IRANSans نمایش داده شود.</p>
    <pre><code>const x = 1;</code></pre>
  </div>
</body>
</html>
"@
Set-Content -Path $testHtmlPath -Value $html -Encoding UTF8

if ($failures.Count -eq 0) {
    Write-Host "PASS: Markdown preview setup looks correct." -ForegroundColor Green
    Write-Host "Test page: $testHtmlPath" -ForegroundColor Gray
    exit 0
}

Write-Host "Verification failed with $($failures.Count) issue(s)." -ForegroundColor Red
exit 1
