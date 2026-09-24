#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | Advanced DNS operations

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only unless advanced DNS values are explicitly supplied. Existing conflicting records and zones are not overwritten.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ZoneName,
    [string]$AliasName = 'az802-portal',
    [string]$AliasTarget,
    [string]$ReverseNetwork,
    [string]$Forwarder
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | Advanced DNS operations'
if (-not (Test-Az802Command Get-DnsServerZone)) { Write-Az802Status SKIP 'DNS Server management tools are not available.'; return }
Import-Module DnsServer
$Context = Get-Az802DomainContext
if (-not $ZoneName) { $ZoneName = $Context.DnsRoot }
if (-not $ZoneName) { Write-Az802Status SKIP 'No DNS zone was detected. Supply -ZoneName.'; return }
if (-not (Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP ('Zone not found: {0}' -f $ZoneName); return }

# Step 1: Create or verify a course CNAME alias only when a valid target is supplied.
Write-Az802Step 1 'Optional course CNAME alias'
if ($AliasTarget) {
    try { Resolve-DnsName $AliasTarget -ErrorAction Stop | Out-Null } catch { throw ('Alias target does not resolve: {0}' -f $AliasTarget) }
    $ExistingAlias = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $AliasName -RRType CName -ErrorAction SilentlyContinue
    if ($ExistingAlias) {
        $Current = [string]$ExistingAlias.RecordData.HostNameAlias
        if ($Current.TrimEnd('.') -ine $AliasTarget.TrimEnd('.')) { throw ('Existing CNAME {0} points to {1}; refusing to overwrite it.' -f $AliasName,$Current) }
        Write-Az802Status OK ('CNAME already points to {0}.' -f $Current)
    } elseif ($PSCmdlet.ShouldProcess($AliasName,'Create CNAME')) {
        Add-DnsServerResourceRecordCName -ZoneName $ZoneName -Name $AliasName -HostNameAlias $AliasTarget | Out-Null
    }
}

# Step 2: Create a reverse zone only from an explicit ordinary IPv4 CIDR.
Write-Az802Step 2 'Optional reverse lookup zone'
if ($ReverseNetwork) {
    if ($ReverseNetwork -notmatch '^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\/(8|16|24)$') { throw 'Automatic reverse-zone creation is limited to /8, /16 or /24 IPv4 networks.' }
    $NetworkAddress = $ReverseNetwork.Split('/')[0]
    if (-not (Test-Az802IPv4Address $NetworkAddress)) { throw 'ReverseNetwork contains an invalid IPv4 address.' }
    $Octets = $NetworkAddress.Split('.')
    $Prefix = [int]$ReverseNetwork.Split('/')[1]
    $ReverseZoneName = switch ($Prefix) {
        8  { '{0}.in-addr.arpa' -f $Octets[0] }
        16 { '{1}.{0}.in-addr.arpa' -f $Octets[0],$Octets[1] }
        24 { '{2}.{1}.{0}.in-addr.arpa' -f $Octets[0],$Octets[1],$Octets[2] }
    }
    $ExistingReverse = Get-DnsServerZone -Name $ReverseZoneName -ErrorAction SilentlyContinue
    if ($ExistingReverse) { Write-Az802Status OK ('Reverse zone already exists: {0}' -f $ReverseZoneName) }
    elseif ($PSCmdlet.ShouldProcess($ReverseNetwork,('Create reverse zone {0}' -f $ReverseZoneName))) {
        if (Test-Az802IsDomainController) { Add-DnsServerPrimaryZone -NetworkId $ReverseNetwork -ReplicationScope Domain | Out-Null }
        else { Add-DnsServerPrimaryZone -NetworkId $ReverseNetwork -ZoneFile ($ReverseZoneName + '.dns') | Out-Null }
    }
}

# Step 3: Add a forwarder only when explicitly supplied.
Write-Az802Step 3 'Optional DNS forwarder'
if ($Forwarder) {
    if (-not (Test-Az802IPv4Address $Forwarder)) { throw 'Forwarder must be a valid IPv4 address.' }
    $CurrentForwarders = @(Get-DnsServerForwarder -ErrorAction SilentlyContinue).IPAddress.IPAddressToString
    if ($CurrentForwarders -contains $Forwarder) { Write-Az802Status OK ('DNS forwarder already exists: {0}' -f $Forwarder) }
    elseif ($PSCmdlet.ShouldProcess($Forwarder,'Add DNS forwarder')) { Add-DnsServerForwarder -IPAddress $Forwarder | Out-Null }
}
Get-DnsServerZone
Get-DnsServerForwarder -ErrorAction SilentlyContinue
