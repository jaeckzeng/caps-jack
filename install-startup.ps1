Write-Host "========================================"
Write-Host " Caps Lock - install startup task"
Write-Host "========================================"
Write-Host ""

# check admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting admin..."
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# find AutoHotkey v2
$candidates = @(
    "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe",
    "C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe",
    "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe",
    "C:\Program Files\AutoHotkey\AutoHotkey64.exe",
    "C:\Program Files\AutoHotkey\AutoHotkey.exe"
)
$ahkPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ahkPath) {
    $cmd = Get-Command autohotkey.exe, AutoHotkey64.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $ahkPath = $cmd.Source }
}
if (-not $ahkPath -or -not (Test-Path $ahkPath)) {
    Write-Host "[ERROR] AutoHotkey v2 not found, please install AutoHotkey v2 first" -ForegroundColor Red
    Write-Host "Download: https://www.autohotkey.com/"
    exit 1
}

# find script
$scriptPath = Join-Path $PSScriptRoot "caps-remap.ahk"
if (-not (Test-Path $scriptPath)) {
    Write-Host "[ERROR] caps-remap.ahk not found" -ForegroundColor Red
    exit 1
}

Write-Host "AutoHotkey: $ahkPath"
Write-Host "Script:     $scriptPath"
Write-Host ""

# remove old task
schtasks /delete /tn "CapsJack" /f 2>$null | Out-Null

# create task
$action = New-ScheduledTaskAction -Execute $ahkPath -Argument "`"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive

try {
    Register-ScheduledTask -TaskName "CapsJack" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
    Write-Host "[OK] Startup task 'CapsJack' created" -ForegroundColor Green
    Write-Host "Will auto-run as admin on next login"
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
