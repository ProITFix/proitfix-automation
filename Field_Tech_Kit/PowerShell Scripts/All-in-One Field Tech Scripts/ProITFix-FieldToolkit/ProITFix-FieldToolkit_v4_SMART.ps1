# ProITFix-FieldToolkit_v4_SMART.ps1

function Write-Color {
    param($text, $color="White")
    Write-Host $text -ForegroundColor $color
}

function Confirm-Action {
    param($message)

    Write-Color "`n$message" Yellow
    $choice = Read-Host "Proceed? (Y/N)"
    if ($choice -ne "Y" -and $choice -ne "y") {
        Write-Color "Action cancelled." Red
        return $false
    }
    return $true
}

# =============================
# DIAGNOSTICS
# =============================
function Run-Diagnostics {

    if (-not (Confirm-Action "Run FULL diagnostics? (Safe, read-only)")) { return }

    Write-Color "Running diagnostics..." Cyan

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
    Write-Color "Diagnostics complete." Green
}

# =============================
# SMART ANALYSIS ENGINE
# =============================
function Analyze-Issues {

    $global:analysis = @()
    $global:category = "Unknown"
    $global:confidence = "Low"
    $global:nextSteps = @()

    if (-not $networkOK) {
        $analysis += "Network connectivity issue"
        $category = "Network"
        $confidence = "High"
        $nextSteps += "Check network jack / cable"
        $nextSteps += "Verify VLAN / IP assignment"
    }

    elseif (-not $defaultPrinter) {
        $analysis += "No default printer (Epic impact)"
        $category = "Printer"
        $confidence = "High"
        $nextSteps += "Set default printer"
        $nextSteps += "Verify printer mapping"
    }

    elseif ($displayEvents.Count -gt 5) {
        $analysis += "GPU/driver instability"
        $category = "Display"
        $confidence = "Medium"
        $nextSteps += "Update GPU driver via Software Center"
        $nextSteps += "Test with different monitor"
    }

    elseif ($explorerEvents.Count -gt 2) {
        $analysis += "Explorer/OS instability"
        $category = "OS"
        $confidence = "Medium"
        $nextSteps += "Restart Explorer"
        $nextSteps += "Consider reimage if persistent"
    }

    else {
        $analysis += "Likely hardware issue (no logs found)"
        $category = "Hardware"
        $confidence = "Low"
        $nextSteps += "Swap monitor/cable"
        $nextSteps += "Test with known-good workstation"
    }
}

# =============================
# SMART GUIDANCE
# =============================
function Smart-Recommendation {

    if (-not (Confirm-Action "Show SMART recommendation?")) { return }

    Write-Color "`n==== SMART ANALYSIS ====" Cyan
    Write-Color "Category: $category" Yellow
    Write-Color "Confidence: $confidence" Yellow

    Write-Color "`nFindings:" Green
    $analysis | ForEach-Object { Write-Color "- $_" White }

    Write-Color "`nRecommended Next Steps:" Cyan
    $nextSteps | ForEach-Object { Write-Color "→ $_" White }
}

# =============================
# TECH SUMMARY
# =============================
function Show-Summary {

    if (-not (Confirm-Action "Generate ServiceNow summary?")) { return }

    $summary = @"
--- TECH SUMMARY ---
Device: $env:COMPUTERNAME
User: $env:USERNAME
Category: $category
Confidence: $confidence
Network: $(if($networkOK){"OK"}else{"ISSUE"})
Default Printer: $(if($defaultPrinter){$defaultPrinter.Name}else{"NOT SET"})
Imprivata: $(if($imprivata){"Running"}else{"Not Running"})
Citrix: $(if($citrix){"Active"}else{"Inactive"})
Findings: $($analysis -join "; ")
Next Steps: $($nextSteps -join "; ")
--------------------
"@

    Write-Color "`n===== TECH SUMMARY =====" Green
    Write-Color $summary White

    $summary | Set-Clipboard
}

# =============================
# QUICK FIX (SAFE + CONFIRMED)
# =============================
function Quick-Fix {

    if (-not (Confirm-Action "Run Quick Fix? (Safe actions only)")) { return }

    if ($category -eq "Printer") {
        Start-Process "ms-settings:printers"
    }

    if ($category -eq "OS") {
        if (Confirm-Action "Restart Explorer?") {
            Stop-Process explorer -Force
            Start-Process explorer
        }
    }

    if ($category -eq "Display") {
        Write-Color "Recommend driver update via Software Center" Yellow
    }

    Write-Color "Quick Fix complete." Green
}

# =============================
# MENU
# =============================
function Main-Menu {
    do {
        Write-Color "`n==== PROITFIX TOOLKIT v4 SMART ====" Cyan
        Write-Color "1. Run Diagnostics"
        Write-Color "2. Smart Recommendation (What should I do?)"
        Write-Color "3. Show Tech Summary"
        Write-Color "4. Quick Fix (Guided)"
        Write-Color "5. Exit"

        $choice = Read-Host "Select option"

        switch ($choice) {
            "1" { Run-Diagnostics }
            "2" { Smart-Recommendation }
            "3" { Show-Summary }
            "4" { Quick-Fix }
        }

    } while ($choice -ne "5")
}

# START
Main-Menu