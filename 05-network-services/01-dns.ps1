#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | DNS

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspects DNS by default. Role installation, zone creation and A-record creation are explicit and conflict-aware.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [string]$ZoneName,
    [switch]$CreateZone,
    [string]$RecordName,
    [string]$IPv4Address
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | DNS'
# Step 1: Inspect DNS role and zones.
Write-Az802Step 1 'Inspect DNS Server state'
$Role = Get-WindowsFeature DNS
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install DNS Server')) { Install-WindowsFeature DNS -IncludeManagementTools | Out-Host }
if (-not (Get-WindowsFeature DNS).Installed) { Write-Az802Status SKIP 'DNS Server is not installed.'; return }
Import-Module DnsServer
Get-Service DNS
Get-DnsServerZone

# Step 2: Resolve the zone name from the real domain unless an explicit standalone zone is supplied.
Write-Az802Step 2 'Resolve the lab zone'
$Context = Get-Az802DomainContext
if (-not $ZoneName) {
    if ($Context.DnsRoot) { $ZoneName = $Context.DnsRoot }
    else { $Config = Import-Az802Config -RepoRoot $RepoRoot; $ZoneName = $Config.DefaultDomainName }
}
$Zone = Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue
if (-not $Zone -and $CreateZone) {
    if ($Context.PartOfDomain -and (Test-Az802IsDomainController)) {
        if ($PSCmdlet.ShouldProcess($ZoneName,'Create AD-integrated primary DNS zone')) { Add-DnsServerPrimaryZone -Name $ZoneName -ReplicationScope Domain -DynamicUpdate Secure | Out-Null }
    } elseif ($PSCmdlet.ShouldProcess($ZoneName,'Create file-backed primary DNS zone')) {
        Add-DnsServerPrimaryZone -Name $ZoneName -ZoneFile ($ZoneName + '.dns') -DynamicUpdate None | Out-Null
    }
}
$Zone = Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue
if (-not $Zone) { Write-Az802Status INFO ('Zone {0} does not exist. Use -CreateZone only when that is intentional.' -f $ZoneName); return }

# Step 3: Create or verify one explicit A record.
Write-Az802Step 3 'Optional A record'
if ($RecordName -and $IPv4Address) {
    if (-not (Test-Az802IPv4Address $IPv4Address)) { throw 'IPv4Address is invalid.' }
    $Existing = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $RecordName -RRType A -ErrorAction SilentlyContinue
    if ($Existing) {
        $Current = [string]$Existing.RecordData.IPv4Address
        if ($Current -ne $IPv4Address) { throw ('A record {0}.{1} already points to {2}; refusing to overwrite it in the normal DNS script.' -f $RecordName,$ZoneName,$Current) }
        Write-Az802Status OK 'A record already matches the requested address.'
    } elseif ($PSCmdlet.ShouldProcess(('{0}.{1}' -f $RecordName,$ZoneName),'Create A record')) {
        Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name $RecordName -IPv4Address $IPv4Address | Out-Null
    }
    Resolve-DnsName ('{0}.{1}' -f $RecordName,$ZoneName) -Server 127.0.0.1
}
