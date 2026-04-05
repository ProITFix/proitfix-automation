# Get Laptop Charging & Battery Health Status
# Safe, read-only diagnostic script

Write-Host "=== Battery & Charging Diagnostics ===" -ForegroundColor Cyan

# Check if system has a battery
$battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue

if (-not $battery) {
    Write-Host "No battery detected (desktop or battery not recognized)." -ForegroundColor Yellow
    return
}

# Display battery status
Write-Host "`n--- Battery Status ---" -ForegroundColor Green
$battery | Select-Object `
    Name,
    BatteryStatus,
    EstimatedChargeRemaining,
    EstimatedRunTime,
    Status | Format-List

# Interpret BatteryStatus
Write-Host "`n--- Battery Status Meaning ---" -ForegroundColor Green
Write-Host "1 = Discharging"
Write-Host "2 = AC Connected / Charging"
Write-Host "3 = Fully Charged"
Write-Host "4 = Low"
Write-Host "5 = Critical"
Write-Host "6+ = Unknown / Issue"

# Check power plan info
Write-Host "`n--- Active Power Plan ---" -ForegroundColor Green
powercfg /getactivescheme

# Generate battery report (saved to user's desktop)
$reportPath = "$env:USERPROFILE\Desktop\battery-report.html"
powercfg /batteryreport /output $reportPath | Out-Null

Write-Host "`nBattery report generated at:" -ForegroundColor Cyan
Write-Host $reportPath

# Quick interpretation hint
Write-Host "`n--- Quick Interpretation ---" -ForegroundColor Cyan
Write-Host "- If BatteryStatus = 2 but % not increasing → Battery issue"
Write-Host "- If no AC detected → Charger or port issue"
Write-Host "- If battery not detected → Hardware failure"

Write-Host "`n=== End of Diagnostics ===" -ForegroundColor Cyan
```
