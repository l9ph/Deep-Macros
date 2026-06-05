# Instala o actualiza el framework DMacros desde GitHub
$ErrorActionPreference = "Stop"
$ahk = Get-Command autohotkey.exe -ErrorAction SilentlyContinue
if (-not $ahk) {
    $candidates = @(
        "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey.exe",
        "${env:ProgramFiles}\AutoHotkey\AutoHotkey.exe",
        "${env:LocalAppData}\Programs\AutoHotkey\v2\AutoHotkey.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { $ahk = $p; break }
    }
}
if (-not $ahk) {
    Write-Host "Instala AutoHotkey v2: https://www.autohotkey.com/" -ForegroundColor Red
    exit 1
}
$updater = Join-Path $PSScriptRoot "UpdateFromGit.ahk"
$installRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
& $ahk $updater $installRoot
exit $LASTEXITCODE
