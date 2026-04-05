# Reset & Diagnose Network Drive (K:)

Write-Host "=== Network Drive (K:) Troubleshooter ===" -ForegroundColor Cyan

# Step 1: Check network connectivity
Write-Host "`n[1] Testing network connectivity..." -ForegroundColor Yellow
$server = Read-Host "Enter file server name (e.g. fileserver01)"
if (Test-Connection -ComputerName $server -Count 2 -Quiet) {
    Write-Host "✅ Network connectivity OK" -ForegroundColor Green
} else {
    Write-Host "❌ Cannot reach server. Check network/VPN/DNS" -ForegroundColor Red
}

# Step 2: Show current mappings
Write-Host "`n[2] Current mapped drives:" -ForegroundColor Yellow
net use

# Step 3: Remove K: drive if exists
Write-Host "`n[3] Removing existing K: mapping..." -ForegroundColor Yellow
net use K: /delete /y | Out-Null
Write-Host "Done."

# Step 4: Re-map drive
Write-Host "`n[4] Re-mapping K: drive..." -ForegroundColor Yellow
$path = Read-Host "Enter full UNC path (e.g. \\server\share)"

try {
    net use K: $path /persistent:no
    Write-Host "✅ Drive mapped successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to map drive" -ForegroundColor Red
}

# Step 5: Test access
Write-Host "`n[5] Testing access to K: drive..." -ForegroundColor Yellow
if (Test-Path "K:\") {
    Write-Host "✅ K: drive is accessible" -ForegroundColor Green
} else {
    Write-Host "❌ Cannot access K: drive" -ForegroundColor Red
}

# Step 6: Credential Manager reminder
Write-Host "`n[6] If still failing:" -ForegroundColor Yellow
Write-Host "- Open Credential Manager and remove saved entries for the file server"
Write-Host "- Then reboot and try again"

Write-Host "`n=== Troubleshooting Complete ===" -ForegroundColor Cyan
```
