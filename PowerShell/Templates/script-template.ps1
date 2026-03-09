<#
.SYNOPSIS
    Short description of the script.

.DESCRIPTION
    Detailed explanation of what the script does.

.AUTHOR
    Damien Young

.VERSION
    1.0

.DATE
    2026

.EXAMPLE
    .\script-name.ps1 -ComputerName PC01
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ComputerName = "localhost"
)

# ===== Logging =====

$LogFile = ".\logs\$(Get-Date -Format 'yyyy-MM-dd')-script.log"

function Write-Log {
    param (
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp : $Message"

    Write-Output $entry
    Add-Content -Path $LogFile -Value $entry
}

# ===== Script Start =====

Write-Log "Script started."

try {

    Write-Log "Target computer: $ComputerName"

    # Example operation
    Get-Service | Out-Null

    Write-Log "Operation completed successfully."

}
catch {

    Write-Log "ERROR: $_"
    exit 1

}

Write-Log "Script finished."