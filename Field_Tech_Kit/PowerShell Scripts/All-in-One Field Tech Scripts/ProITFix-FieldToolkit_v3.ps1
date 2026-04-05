# ProITFix-FieldToolkit_v3.ps1

function Write-Color {
   param($text, $color="White")
   Write-Host $text -ForegroundColor $color
}

function Run-Diagnostics {

   $global:networkOK = Test-Connection -ComputerName 8.8.8.8 -Quiet -Count 1
   $global:printers = Get-Printer
   $global:defaultPrinter = $printers | Where-Object {$_.Default -eq $true}
   $global:gpu = Get-WmiObject Win32_VideoController
   $global:systemLogs = Get-WinEvent -LogName System -MaxEvents 150
   $global:appLogs = Get-WinEvent -LogName Application -MaxEvents 150

   $global:displayEvents = $systemLogs | Where-Object {$_.Message -match "display|driver"}
   $global:explorerEvents = $appLogs | Where-Object {$_.Message -match "explorer.exe"}

   $global:imprivata = Get-Process -Name "Imprivata*" -ErrorAction SilentlyContinue
   $global:citrix = Get-Process -Name "wfcrun32" -ErrorAction SilentlyContinue

   Analyze-Issues
}

function Analyze-Issues {
   $global:analysis = @()

   if (-not $networkOK) { $analysis += "Network issue" }
   if (-not $defaultPrinter) { $analysis += "No default printer (Epic impact)" }
   if ($displayEvents.Count -gt 5) { $analysis += "GPU/driver instability" }
   if ($explorerEvents.Count -gt 2) { $analysis += "Explorer/OS instability" }

   if ($analysis.Count -eq 0) { $analysis += "No major issues detected" }
}

function Show-Summary {
   $summary = @"
--- TECH SUMMARY ---
Device: $env:COMPUTERNAME
User: $env:USERNAME
Network: $(if($networkOK){"OK"}else{"ISSUE"})
Default Printer: $(if($defaultPrinter){$defaultPrinter.Name}else{"NOT SET"})
Imprivata: $(if($imprivata){"Running"}else{"Not Running"})
Citrix: $(if($citrix){"Active"}else{"Inactive"})
Findings: $($analysis -join "; ")
--------------------
"@

   Write-Color "`n===== TECH SUMMARY =====" Green
   Write-Color $summary White

   $summary | Set-Clipboard
}

function Quick-Fix {
   Write-Color "`nRunning Quick Fixes..." Yellow

   if (-not $defaultPrinter) {
       Write-Color "No default printer found. Prompting user to set one..." Red
       Start-Process "ms-settings:printers"
   }

   if ($imprivata -eq $null) {
       Write-Color "Restarting Imprivata service..." Yellow
       Get-Service | Where-Object {$_.Name -like "*imprivata*"} | Restart-Service -ErrorAction SilentlyContinue
   }

   Write-Color "Restarting Explorer..." Yellow
   Stop-Process -Name explorer -Force
   Start-Process explorer

   Write-Color "Quick Fix Completed" Green
}

function Network-Tools {
   Write-Color "`nRunning Network Tools..." Cyan
   ipconfig
   Write-Color "`nPinging Google..." Yellow
   Test-Connection 8.8.8.8 -Count 2
}

function Printer-Tools {
   Write-Color "`nInstalled Printers:" Cyan
   Get-Printer | Format-Table Name, Default, Status
}

function Main-Menu {
   do {
       Write-Color "`n==== PROITFIX TOOLKIT v3 ====" Cyan
       Write-Color "1. Run Full Diagnostics"
       Write-Color "2. Show Tech Summary"
       Write-Color "3. Quick Fix (Safe)"
       Write-Color "4. Network Tools"
       Write-Color "5. Printer Tools"
       Write-Color "6. Exit"

       $choice = Read-Host "Select option"

       switch ($choice) {
           "1" { Run-Diagnostics }
           "2" { Show-Summary }
           "3" { Quick-Fix }
           "4" { Network-Tools }
           "5" { Printer-Tools }
       }

   } while ($choice -ne "6")
}

# START
Main-Menu
	

________________


⚡ How You’ll Actually Use This in the Field
🔹 Normal Ticket Flow:
1. Run script
2. Press 1 (Full Diagnostics)
3. Press 2 (Tech Summary)
4. Paste into ServiceNow
5. Fix based on findings
________________


🔹 If User is Standing There Waiting:
* Press 3 (Quick Fix)
👉 Fast fixes:
* Restart Explorer
* Check printer
* Restart Imprivata
________________


🔹 If It’s Network / Printer Issue:
   * Press 4 or 5 for focused tools