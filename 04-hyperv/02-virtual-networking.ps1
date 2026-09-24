#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | Hyper-V virtual networking

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. -Create builds a course-scoped internal switch, gateway and NAT after validating the requested prefix.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Create,
    [string]$SwitchName = 'AZ802-LabNAT',
    [string]$NatName = 'AZ802-LabNAT-Network',
    [string]$GatewayAddress = '192.168.100.1',
    [ValidateRange(1,32)][int]$PrefixLength = 24,
    [string]$NatPrefix = '192.168.100.0/24'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | Hyper-V virtual networking'
Assert-Az802Command -Name Get-VMSwitch -Hint 'Install Hyper-V management tools first.'

# Step 1: Inspect existing virtual switches, management adapters and NAT objects.
Write-Az802Step 1 'Inspect current Hyper-V networking'
Get-VMSwitch | Select-Object Name,SwitchType,NetAdapterInterfaceDescription
Get-VMNetworkAdapter -ManagementOS | Select-Object Name,SwitchName,MacAddress,Status
Get-NetNat -ErrorAction SilentlyContinue | Select-Object Name,InternalIPInterfaceAddressPrefix

# Step 2: Create or verify the course internal switch.
Write-Az802Step 2 'Create or verify the internal NAT switch'
if (-not $Create) { Write-Az802Status INFO 'Use -Create to build the internal switch and NAT.'; return }
if (-not (Test-Az802IPv4Address $GatewayAddress)) { throw 'GatewayAddress must be a valid IPv4 address.' }
$PrefixParts = $NatPrefix -split '/'
if ($PrefixParts.Count -ne 2) { throw 'NatPrefix must use CIDR notation, for example 192.168.100.0/24.' }
$Network = $PrefixParts[0]; $NatLength = [int]$PrefixParts[1]
if ($NatLength -ne $PrefixLength) { throw 'PrefixLength must match the CIDR length in NatPrefix.' }
if (-not (Test-Az802AddressInPrefix -Address $GatewayAddress -NetworkAddress $Network -PrefixLength $PrefixLength)) { throw 'GatewayAddress is not inside NatPrefix.' }
$Switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if ($Switch -and $Switch.SwitchType -ne 'Internal') { throw ('A switch named {0} exists but is not Internal.' -f $SwitchName) }
if (-not $Switch -and $PSCmdlet.ShouldProcess($SwitchName,'Create internal VMSwitch')) { New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null; Write-Az802Status CREATE ('Created switch {0}' -f $SwitchName) }
$Alias = 'vEthernet ({0})' -f $SwitchName
$ExistingIp = Get-NetIPAddress -InterfaceAlias $Alias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object IPAddress -eq $GatewayAddress
if (-not $ExistingIp -and $PSCmdlet.ShouldProcess($Alias,('Add gateway {0}/{1}' -f $GatewayAddress,$PrefixLength))) { New-NetIPAddress -IPAddress $GatewayAddress -PrefixLength $PrefixLength -InterfaceAlias $Alias | Out-Null }
$Nat = Get-NetNat -Name $NatName -ErrorAction SilentlyContinue
if ($Nat -and $Nat.InternalIPInterfaceAddressPrefix -ne $NatPrefix) { throw ('NAT {0} exists with prefix {1}, not {2}.' -f $NatName,$Nat.InternalIPInterfaceAddressPrefix,$NatPrefix) }
$ConflictingNat = Get-NetNat -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne $NatName -and $_.InternalIPInterfaceAddressPrefix -eq $NatPrefix }
if ($ConflictingNat) { throw ('Another NAT already owns prefix {0}: {1}' -f $NatPrefix,($ConflictingNat.Name -join ', ')) }
if (-not $Nat -and $PSCmdlet.ShouldProcess($NatName,('Create NAT for {0}' -f $NatPrefix))) { New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $NatPrefix | Out-Null }
Get-VMSwitch -Name $SwitchName
Get-NetIPAddress -InterfaceAlias $Alias -AddressFamily IPv4
Get-NetNat -Name $NatName
