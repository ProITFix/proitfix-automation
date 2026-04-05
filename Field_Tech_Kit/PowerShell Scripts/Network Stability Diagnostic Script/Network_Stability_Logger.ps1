# Network Stability Logger Script
# Logs ping results + network events for intermittent issues

Write-Host "=== Network Stability Logger Starting ===" -ForegroundColor Cyan

# Create log file on Desktop
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "$env:USERPROFILE\Desktop\Network_Log_$timestamp.txt"

"=== Network Log Started: $(Get-Date) ===" | Out-File $logFile

# Get active adapter
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true }

if (-not $adapter) {
    Write-Host "No active wired adapter found." -ForegroundColor Red
    exit
}

"Adapter: $($adapter.Name) - $($adapter.InterfaceDescription)" | Out-File $logFile -Append

# Get gateway
$gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
            Sort-Object RouteMetric |
            Select-Object -First 1).NextHop

"Gateway: $gateway" | Out-File $logFile -Append

Write-Host "Logging to: $logFile" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Yellow

# Continuous monitoring loop
while ($true) {

    $time = Get-Date -Format "HH:mm:ss"

    # Ping test (single ping for continuous logging)
    $ping = Test-Connection -ComputerName $gateway -Count 1 -ErrorAction SilentlyContinue

    if ($ping) {
        $latency = $ping.ResponseTime

        if ($latency -gt 20) {
            $msg = "$time - HIGH LATENCY: $latency ms"
            Write-Host $msg -ForegroundColor Yellow
            $msg | Out-File $logFile -Append
        } else {
            $msg = "$time - OK: $latency ms"
            Write-Host $msg
            $msg | Out-File $logFile -Append
        }
    } else {
        $msg = "$time - PACKET LOSS / NO RESPONSE"
        Write-Host $msg -ForegroundColor Red
        $msg | Out-File $logFile -Append
    }

    # Check for recent disconnect events (last 2 minutes)
    $events = Get-WinEvent -LogName System -MaxEvents 20 | Where-Object {
        $_.TimeCreated -gt (Get-Date).AddMinutes(-2) -and
        ($_.Message -like "*network link is disconnected*" -or $_.Message -like "*reset*")
    }

    foreach ($event in $events) {
        $eventMsg = "$time - EVENT: $($event.Message)"
        Write-Host $eventMsg -ForegroundColor Magenta
        $eventMsg | Out-File $logFile -Append
    }

    Start-Sleep -Seconds 2
}

"=== Network Log Ended: $(Get-Date) ===" | Out-File $logFile -Append