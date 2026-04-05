# Get-DisplayIssues-Diagnostics_v2.ps1
# Advanced diagnostics + auto-analysis

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = "$env:USERPROFILE\Desktop\Display_Diagnostics_$timestamp.txt"

# Header
"==== DISPLAY DIAGNOSTICS REPORT (AUTO-ANALYSIS) ====" | Out-File $outputFile
"Generated: $(Get-Date)" | Out-File $outputFile -Append
"Computer: $env:COMPUTERNAME" | Out-File $outputFile -Append
"`n" | Out-File $outputFile -Append

# -----------------------------
# GPU Info
# -----------------------------
$gpu = Get-WmiObject Win32_VideoController
"==== GPU INFO ====" | Out-File $outputFile -Append
$gpu | Select Name, DriverVersion, Status |
  Format-Table | Out-String | Out-File $outputFile -Append

# -----------------------------
# Collect Logs
# -----------------------------
$systemLogs = Get-WinEvent -LogName System -MaxEvents 300
$appLogs = Get-WinEvent -LogName Application -MaxEvents 300

# Filter Relevant Events
$displayEvents = $systemLogs | Where-Object { $_.Message -match "display|gpu|video|driver" }
$explorerEvents = $appLogs | Where-Object { $_.Message -match "explorer.exe" }
$criticalEvents = Get-WinEvent -FilterHashtable @{
  LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-1)
}

# Output Logs
"==== DISPLAY EVENTS ====" | Out-File $outputFile -Append
$displayEvents | Select TimeCreated, Id, Message |
  Format-Table -Wrap | Out-String | Out-File $outputFile -Append

"==== EXPLORER EVENTS ====" | Out-File $outputFile -Append
$explorerEvents | Select TimeCreated, Id, Message |
  Format-Table -Wrap | Out-String | Out-File $outputFile -Append

"==== CRITICAL EVENTS ====" | Out-File $outputFile -Append
$criticalEvents | Select TimeCreated, Id, ProviderName, Message |
  Format-Table -Wrap | Out-String | Out-File $outputFile -Append

# -----------------------------
# ANALYSIS ENGINE
# -----------------------------
"==== AUTO ANALYSIS ====" | Out-File $outputFile -Append

$analysis = @()

# Driver crash detection
if ($displayEvents | Where-Object { $_.Message -match "stopped responding|recovered" }) {
  $analysis += "⚠️ Likely GPU DRIVER issue (driver crashes detected)"
}

# Explorer crash detection
if ($explorerEvents.Count -gt 2) {
  $analysis += "⚠️ Likely OS / Explorer instability (multiple explorer crashes)"
}

# Critical hardware-like errors
if ($criticalEvents | Where-Object { $_.ProviderName -match "Display" }) {
  $analysis += "⚠️ Possible GPU hardware or deep driver issue"
}

# No logs but issue reported
if ($displayEvents.Count -eq 0 -and $explorerEvents.Count -eq 0) {
  $analysis += "⚠️ No system logs found → Likely hardware (monitor/cable/power)"
}

# Frequent issues
if ($displayEvents.Count -gt 10) {
  $analysis += "⚠️ High frequency display errors → Persistent issue (driver or hardware)"
}

# Default fallback
if ($analysis.Count -eq 0) {
  $analysis += "✅ No clear issue detected → Check monitor, cable, and power first"
}

# Output Analysis
$analysis | ForEach-Object {
  $_ | Out-File $outputFile -Append
}

# -----------------------------
# RECOMMENDED ACTIONS
# -----------------------------
"==== RECOMMENDED ACTIONS ====" | Out-File $outputFile -Append

if ($analysis -match "DRIVER") {
  "→ Update or reinstall GPU driver (Software Center / SCCM)" | Out-File $outputFile -Append
}

if ($analysis -match "Explorer") {
  "→ Consider reimage or OS repair" | Out-File $outputFile -Append
}

if ($analysis -match "hardware") {
  "→ Swap monitor, cable, and test different port" | Out-File $outputFile -Append
}

if ($analysis -match "Persistent") {
  "→ Escalate if issue continues after driver + hardware swap" | Out-File $outputFile -Append
}

if ($analysis -match "No clear") {
  "→ Start with physical checks (most common cause)" | Out-File $outputFile -Append
}

# -----------------------------
# Finish
# -----------------------------
"`nDiagnostics complete. File saved to: $outputFile" | Out-File $outputFile -Append

Write-Host "Diagnostics complete. File saved to:"
Write-Host $outputFile