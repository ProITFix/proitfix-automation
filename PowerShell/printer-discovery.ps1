<#
.SYNOPSIS
Printer discovery tool for IT support.

.DESCRIPTION
Retrieves hostname, MAC address, and manufacturer for a printer based on IP.

.NOTES
Author: Damien Young
Project: ProITFix Automation Toolkit
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter the printer IP address.")]
    [ValidateNotNullOrEmpty()]
    [string]$IPAddress
)

function Test-ValidIpAddress {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Address
    )

    $parsedAddress = $null
    return [System.Net.IPAddress]::TryParse($Address, [ref]$parsedAddress)
}

function Get-ManufacturerFromMac {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$MacAddress
    )

    if ([string]::IsNullOrWhiteSpace($MacAddress)) {
        return "Unknown"
    }

    # Normalize the MAC so we can compare the first 3 octets reliably.
    $normalizedMac = ($MacAddress -replace '[-:.]', '').ToUpperInvariant()
    if ($normalizedMac.Length -lt 6) {
        return "Unknown"
    }

    $oui = $normalizedMac.Substring(0, 6)

    # Local OUI map keeps lookups self-contained and safe for enterprise use.
    $ouiMap = @{
        "00085D" = "HP"
        "001635" = "HP"
        "00237D" = "HP"
        "3CD92B" = "HP"
        "A45D36" = "HP"
        "0001E6" = "Brother"
        "001BA9" = "Brother"
        "14CF92" = "Brother"
        "001122" = "Brother"
        "000074" = "Ricoh"
        "001E0B" = "Ricoh"
        "080046" = "Lexmark"
        "0024E8" = "Lexmark"
        "000048" = "Epson"
        "44D37E" = "Epson"
        "0007CA" = "Xerox"
        "0019E8" = "Xerox"
        "00237B" = "Xerox"
        "000159" = "Canon"
        "0024C8" = "Canon"
        "28924A" = "Canon"
        "000CE7" = "Konica Minolta"
        "080037" = "Konica Minolta"
        "0000F6" = "Kyocera"
        "E091F5" = "Kyocera"
        "00067C" = "Sharp"
        "8C0C90" = "Sharp"
        "001349" = "Dell"
        "B499BA" = "Dell"
        "F8DB88" = "Zebra"
        "84A87E" = "Zebra"
    }

    if ($ouiMap.ContainsKey($oui)) {
        return $ouiMap[$oui]
    }

    return "Unknown"
}

function Get-ReverseDnsName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Address
    )

    try {
        return ([System.Net.Dns]::GetHostEntry($Address)).HostName
    }
    catch {
        return "Unavailable"
    }
}

function Get-MacAddressForIp {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Address
    )

    try {
        $neighbor = Get-NetNeighbor -IPAddress $Address -ErrorAction Stop |
            Where-Object { $_.LinkLayerAddress -and $_.State -ne "Unreachable" } |
            Select-Object -First 1

        if ($neighbor) {
            return $neighbor.LinkLayerAddress.ToUpperInvariant()
        }
    }
    catch {
        # Fall back to arp.exe for systems where Get-NetNeighbor is unavailable or incomplete.
    }

    try {
        $arpEntry = arp -a $Address | Select-String -Pattern '([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}' | Select-Object -First 1
        if ($arpEntry) {
            return $arpEntry.Matches[0].Value.ToUpperInvariant()
        }
    }
    catch {
        return $null
    }

    return $null
}

try {
    # Validate the input before doing any network operation.
    if (-not (Test-ValidIpAddress -Address $IPAddress)) {
        throw "The value '$IPAddress' is not a valid IPv4 or IPv6 address."
    }

    Write-Host ""
    Write-Host "Printer Discovery Results" -ForegroundColor Cyan
    Write-Host ("-" * 40) -ForegroundColor Cyan
    Write-Host "Checking connectivity to $IPAddress..." -ForegroundColor Yellow

    # Ping only the supplied IP address to confirm the device is reachable.
    $isReachable = Test-Connection -ComputerName $IPAddress -Count 1 -Quiet -ErrorAction SilentlyContinue
    if (-not $isReachable) {
        throw "The device at $IPAddress did not respond to ping. Verify the IP address and network connectivity."
    }

    # Once the device responds, query the local neighbor/ARP cache for the MAC address.
    $macAddress = Get-MacAddressForIp -Address $IPAddress
    if (-not $macAddress) {
        $macAddress = "Unavailable"
    }

    # Reverse DNS is a safe single-host lookup that may reveal the printer hostname.
    $hostName = Get-ReverseDnsName -Address $IPAddress

    # Try to infer the vendor from a small built-in OUI table.
    $manufacturer = Get-ManufacturerFromMac -MacAddress $macAddress

    $result = [PSCustomObject]@{
        Hostname     = $hostName
        "IP Address" = $IPAddress
        "MAC Address" = $macAddress
        Manufacturer = $manufacturer
    }

    Write-Host ""
    $result | Format-List
}
catch {
    Write-Host ""
    Write-Host "Printer discovery failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
