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

# find AutoHotkey
$ahkPath = "C:\Program Files\AutoHotkey\AutoHotkey.exe"
if (-not (Test-Path $ahkPath)) {
    $ahkPath = (Get-Command autohotkey.exe -ErrorAction SilentlyContinue).Source
}
if (-not $ahkPath -or -not (Test-Path $ahkPath)) {
    Write-Host "[ERROR] AutoHotkey not found, please install AutoHotkey v1.1 first" -ForegroundColor Red
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
