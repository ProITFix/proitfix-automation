# Define download URL and paths
$hpiaUrl = "https://ftp.hp.com/pub/caps-softpaq/cmit/HPIA.exe"
$downloadPath = "$env:TEMP\HPIA.exe"
$installPath = "C:\Program Files\HP\HPIA\HPIA.exe"

# Download HPIA
Write-Host "Downloading HP Image Assistant..."
Invoke-WebRequest -Uri $hpiaUrl -OutFile $downloadPath -UseBasicParsing

# Install HPIA silently
Write-Host "Installing HP Image Assistant..."
Start-Process -FilePath $downloadPath -ArgumentList "/s" -Wait

# Verify installation
if (Test-Path $installPath) {
   Write-Host "HPIA installed successfully at $installPath"
} else {
   Write-Host "HPIA installation may have failed. Please verify manually."
}