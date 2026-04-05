# Get-DisplayIssues-Diagnostics.ps1
# Collects display, GPU, and crash-related logs for troubleshooting

# Output file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = "$env:USERPROFILE\Desktop\Display_Diagnostics_$timestamp.txt"

# Header
"==== DISPLAY DIAGNOSTICS REPORT ====" | Out-File $outputFile
"Generated: $(Get-Date)" | Out-File $outputFile -Append
"Computer: $env:COMPUTERNAME" | Out-File $outputFile -Append
"User: $env:USERNAME" | Out-File $outputFile -Append
"`n" | Out-File $outputFile -Append

# -----------------------------
# GPU / Display Adapter Info
# -----------------------------
"==== GPU / DISPLAY ADAPTER INFO ====" | Out-File $outputFile -Append
Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion, Status |
   Format-Table | Out-String | Out-File $outputFile -Append

# -----------------------------
# Recent System Errors (Display)
# -----------------------------
"==== SYSTEM LOG (DISPLAY / GPU RELATED) ====" | Out-File $outputFile -Append
Get-WinEvent -LogName System -MaxEvents 200 |
   Where-Object {
       $_.Message -match "display|gpu|video|driver"
   } |
   Select-Object TimeCreated, Id, LevelDisplayName, Message |
   Format-Table -Wrap | Out-String |
   Out-File $outputFile -Append

# -----------------------------
# Explorer Crashes
# -----------------------------
"==== EXPLORER CRASHES ====" | Out-File $outputFile -Append
Get-WinEvent -LogName Application -MaxEvents 200 |
   Where-Object {
       $_.Message -match "explorer.exe"
   } |
   Select-Object TimeCreated, Id, LevelDisplayName, Message |
   Format-Table -Wrap | Out-String |
   Out-File $outputFile -Append

# -----------------------------
# Critical Errors (System)
# -----------------------------
"==== CRITICAL / ERROR EVENTS ====" | Out-File $outputFile -Append
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-1)} |
   Select-Object TimeCreated, Id, ProviderName, Message |
   Format-Table -Wrap | Out-String |
   Out-File $outputFile -Append

# -----------------------------
# Uptime Info
# -----------------------------
"==== SYSTEM UPTIME ====" | Out-File $outputFile -Append
(Get-CimInstance Win32_OperatingSystem).LastBootUpTime |
   Out-File $outputFile -Append

# -----------------------------
# Completion Message
# -----------------------------
"`nDiagnostics complete. File saved to: $outputFile" | Out-File $outputFile -Append

Write-Host "Diagnostics complete. File saved to:"
Write-Host $outputFile