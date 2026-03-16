<#
.SYNOPSIS
    Collects basic workstation networking and OS details for helpdesk troubleshooting.

.DESCRIPTION
    Gathers hostname, IPv4 addresses, DNS servers, default gateway, Windows version,
    and a simple internet connectivity test, then prints the results in a clean format.

.AUTHOR
    OpenAI Codex

.VERSION
    1.1

.DATE
    2026-03-15

.EXAMPLE
    .\system-diagnostic.ps1
#>

function Get-SectionLine {
    param (
        [string]$Title
    )

    return ('=' * 72), $Title, ('=' * 72)
}

function Format-Value {
    param (
        [string]$Label,
        [string[]]$Value
    )

    $displayValue = if ($Value -and $Value.Count -gt 0) {
        $filteredValues = $Value | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if ($filteredValues) { $filteredValues -join ', ' } else { 'Not detected' }
    }
    else {
        'Not detected'
    }

    '{0,-22}: {1}' -f $Label, $displayValue
}

function Get-HostnameValue {
    if (-not [string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
        return $env:COMPUTERNAME
    }

    try {
        return [System.Net.Dns]::GetHostName()
    }
    catch {
        return $null
    }
}

function Get-WindowsVersionValue {
    try {
        $currentVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $productName = $currentVersion.ProductName
        $displayVersion = $currentVersion.DisplayVersion
        $releaseId = $currentVersion.ReleaseId
        $buildNumber = $currentVersion.CurrentBuild

        $versionLabel = if ($displayVersion) { $displayVersion } elseif ($releaseId) { $releaseId } else { $null }

        if ($productName -and $versionLabel -and $buildNumber) {
            return "$productName $versionLabel (Build $buildNumber)"
        }

        if ($productName -and $buildNumber) {
            return "$productName (Build $buildNumber)"
        }

        return $productName
    }
    catch {
        return $null
    }
}

function Get-NetworkDetails {
    $details = @{
        IPv4Addresses   = @()
        DnsServers      = @()
        DefaultGateways = @()
    }

    try {
        $netConfig = Get-NetIPConfiguration -ErrorAction Stop | Where-Object {
            $_.NetAdapter.Status -eq 'Up'
        }

        foreach ($adapter in $netConfig) {
            $details.IPv4Addresses += $adapter.IPv4Address | ForEach-Object { $_.IPv4Address }
            $details.DnsServers += $adapter.DNSServer.ServerAddresses
            $details.DefaultGateways += $adapter.IPv4DefaultGateway | ForEach-Object { $_.NextHop }
        }
    }
    catch {
        $ipconfigOutput = ipconfig /all
        $currentAdapter = $null
        $continuationField = $null

        foreach ($line in $ipconfigOutput) {
            if ($line -match '^[A-Za-z].*adapter\s+(.+):$') {
                $currentAdapter = $matches[1]
                $continuationField = $null
                continue
            }

            if (-not $currentAdapter) {
                continue
            }

            if ($line -match 'IPv4 Address[.\s]*:\s*([0-9.]+)') {
                $details.IPv4Addresses += $matches[1]
                $continuationField = $null
                continue
            }

            if ($line -match 'Default Gateway[.\s]*:\s*(.+)$') {
                $gatewayValue = $matches[1].Trim()
                if ($gatewayValue) {
                    $details.DefaultGateways += $gatewayValue
                }
                $continuationField = 'DefaultGateway'
                continue
            }

            if ($line -match 'DNS Servers[.\s]*:\s*(.+)$') {
                $dnsValue = $matches[1].Trim()
                if ($dnsValue) {
                    $details.DnsServers += $dnsValue
                }
                $continuationField = 'DnsServers'
                continue
            }

            if ($line -match '^\s{20,}(\S.+)$') {
                $continuationValue = $matches[1].Trim()
                switch ($continuationField) {
                    'DefaultGateway' {
                        $details.DefaultGateways += $continuationValue
                        continue
                    }
                    'DnsServers' {
                        $details.DnsServers += $continuationValue
                        continue
                    }
                    default {
                        continue
                    }
                }
            }

            $continuationField = $null
        }
    }

    $details.IPv4Addresses = $details.IPv4Addresses | Where-Object { $_ } | Sort-Object -Unique
    $details.DnsServers = $details.DnsServers | Where-Object { $_ } | Sort-Object -Unique
    $details.DefaultGateways = $details.DefaultGateways | Where-Object { $_ } | Sort-Object -Unique

    return $details
}

function Test-InternetConnection {
    param (
        [string[]]$Targets = @('1.1.1.1', '8.8.8.8', 'www.microsoft.com')
    )

    foreach ($target in $Targets) {
        try {
            if (Test-Connection -ComputerName $target -Count 1 -Quiet -ErrorAction Stop) {
                return "Connected (reachable: $target)"
            }
        }
        catch {
            continue
        }
    }

    return 'Failed (no configured test targets responded)'
}

$networkDetails = Get-NetworkDetails
$reportTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$outputLines = @()
$outputLines += Get-SectionLine -Title 'SYSTEM DIAGNOSTIC'
$outputLines += "Generated: $reportTime"
$outputLines += ''
$outputLines += Format-Value -Label 'Hostname' -Value @(Get-HostnameValue)
$outputLines += Format-Value -Label 'IP Address(es)' -Value $networkDetails.IPv4Addresses
$outputLines += Format-Value -Label 'DNS Server(s)' -Value $networkDetails.DnsServers
$outputLines += Format-Value -Label 'Default Gateway' -Value $networkDetails.DefaultGateways
$outputLines += Format-Value -Label 'Windows Version' -Value @(Get-WindowsVersionValue)
$outputLines += Format-Value -Label 'Internet Test' -Value @(Test-InternetConnection)

$outputLines | ForEach-Object { Write-Host $_ }
