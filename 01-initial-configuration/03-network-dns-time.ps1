#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 1 | Network, DNS and time

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Static IPv4 replacement also requires -IUnderstandConnectivityLoss because it can disconnect a remote session. DNS changes require explicit server addresses.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$IPAddress,
    [ValidateRange(1,32)][int]$PrefixLength,
    [string]$DefaultGateway,
    [string[]]$DnsServers,
    [switch]$IUnderstandConnectivityLoss
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 1 | Network, DNS and time'
# Step 1: Discover the current primary interface instead of assuming an interface index.
Write-Az802Step 1 'Discover the primary IPv4 interface'
$Primary = Get-Az802PrimaryAdapter
if (-not $Primary) { throw 'No active IPv4 interface was found.' }
$Primary | Select-Object InterfaceAlias,InterfaceIndex,IPv4Address,IPv4DefaultGateway,DNSServer
Write-Az802Status OK ('Using discovered interface: {0} (index {1})' -f $Primary.InterfaceAlias,$Primary.InterfaceIndex)

# Step 2: Apply a static address only when all values are explicitly supplied.
Write-Az802Step 2 'Optional static IPv4 configuration'
if ($IPAddress -or $DefaultGateway -or $PrefixLength) {
    if (-not $IUnderstandConnectivityLoss) { throw 'Supply -IUnderstandConnectivityLoss before replacing the active IPv4 configuration. This can disconnect a remote session.' }
    if (-not ($IPAddress -and $DefaultGateway -and $PrefixLength)) { throw 'IPAddress, PrefixLength and DefaultGateway must be supplied together.' }
    if (-not (Test-Az802IPv4Address $IPAddress) -or -not (Test-Az802IPv4Address $DefaultGateway)) { throw 'IPAddress and DefaultGateway must be valid IPv4 addresses.' }
    if (-not (Test-Az802AddressInPrefix -Address $DefaultGateway -NetworkAddress $IPAddress -PrefixLength $PrefixLength)) { throw 'IPAddress and DefaultGateway are not in the same prefix.' }
    if ($PSCmdlet.ShouldProcess($Primary.InterfaceAlias,'Replace IPv4 configuration')) {
        Set-NetIPInterface -InterfaceIndex $Primary.InterfaceIndex -Dhcp Disabled
        Get-NetIPAddress -InterfaceIndex $Primary.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object PrefixOrigin -ne 'WellKnown' | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        New-NetIPAddress -InterfaceIndex $Primary.InterfaceIndex -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway | Out-Null
        Write-Az802Status CHANGE 'Static IPv4 configuration applied.'
    }
} else { Write-Az802Status INFO 'No static address requested. Supply -IPAddress, -PrefixLength and -DefaultGateway together to change networking.' }

# Step 3: Configure DNS servers only when explicitly supplied.
Write-Az802Step 3 'Optional DNS client configuration'
if ($DnsServers -and $DnsServers.Count -gt 0) {
    foreach ($Server in $DnsServers) { if (-not (Test-Az802IPv4Address $Server)) { throw ('Invalid DNS server address: {0}' -f $Server) } }
    if ($PSCmdlet.ShouldProcess($Primary.InterfaceAlias,'Set DNS client servers')) { Set-DnsClientServerAddress -InterfaceIndex $Primary.InterfaceIndex -ServerAddresses $DnsServers }
} else { Write-Az802Status INFO 'No DNS-server change requested.' }

# Step 4: Show the resulting network and time-service state.
Write-Az802Step 4 'Verify current state'
Get-NetIPConfiguration -InterfaceIndex $Primary.InterfaceIndex
Get-DnsClientServerAddress -InterfaceIndex $Primary.InterfaceIndex -AddressFamily IPv4
Invoke-Az802Native -FilePath 'w32tm.exe' -ArgumentList @('/query','/status') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null
