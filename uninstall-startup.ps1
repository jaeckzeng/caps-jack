Write-Host "========================================"
Write-Host " Caps Lock - remove startup task"
Write-Host "========================================"
Write-Host ""

# check admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting admin..."
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

try {
    Unregister-ScheduledTask -TaskName "CapsJack" -Confirm:$false -ErrorAction Stop
    Write-Host "[OK] Startup task 'CapsJack' removed" -ForegroundColor Green
} catch {
    Write-Host "[INFO] Task 'CapsJack' not found or already removed" -ForegroundColor Yellow
}
