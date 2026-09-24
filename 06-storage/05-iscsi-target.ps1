#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | iSCSI target

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspects by default. Course target creation requires -Create and real explicit initiator identifiers.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [switch]$Create,
    [string[]]$InitiatorId,
    [ValidateRange(1073741824,10995116277760)][uint64]$Size = 10GB
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | iSCSI target'
# Step 1: Inspect or install iSCSI Target Server.
Write-Az802Step 1 'Inspect iSCSI Target Server state'
$Role=Get-WindowsFeature FS-iSCSITarget-Server
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install iSCSI Target Server')) { Install-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools | Out-Host }
if (-not (Get-WindowsFeature FS-iSCSITarget-Server).Installed) { Write-Az802Status SKIP 'iSCSI Target Server is not installed.'; return }
Get-IscsiServerTarget -ErrorAction SilentlyContinue

# Step 2: Validate initiator identifiers before creating a target.
Write-Az802Step 2 'Validate target inputs'
if (-not $Create) { Write-Az802Status INFO 'Use -Create and supply at least one real -InitiatorId from the initiator machine.'; return }
if (-not $InitiatorId -or $InitiatorId.Count -eq 0) { throw 'Supply one or more real initiator IDs in the form IQN:iqn.example, IPAddress:10.0.0.25, DNSName:host.example, IPv6Address:2001:db8::25 or MACAddress:001122334455.' }
foreach ($Id in $InitiatorId) { if ($Id -notmatch '^(IQN|IPAddress|DNSName|IPv6Address|MACAddress):.+$') { throw ('Invalid iSCSI initiator ID format: {0}' -f $Id) } }
$Path='C:\AZ802\iSCSI\AZ802-Disk01.vhdx'; Initialize-Az802Directory -Path (Split-Path $Path -Parent)

# Step 3: Create or verify the course virtual disk and target.
Write-Az802Step 3 'Create or verify course iSCSI objects'
if (-not (Get-IscsiVirtualDisk -Path $Path -ErrorAction SilentlyContinue) -and $PSCmdlet.ShouldProcess($Path,'Create iSCSI virtual disk')) { New-IscsiVirtualDisk -Path $Path -Size $Size | Out-Null }
$Target=Get-IscsiServerTarget -TargetName 'AZ802-Target01' -ErrorAction SilentlyContinue
if (-not $Target -and $PSCmdlet.ShouldProcess('AZ802-Target01','Create iSCSI target')) { New-IscsiServerTarget -TargetName 'AZ802-Target01' -InitiatorIds $InitiatorId | Out-Null; $Target=Get-IscsiServerTarget -TargetName 'AZ802-Target01' }
elseif ($Target) {
    $Current=@($Target.InitiatorIds)
    $Missing=@($InitiatorId | Where-Object { $Current -notcontains $_ })
    if ($Missing.Count -gt 0 -and $PSCmdlet.ShouldProcess('AZ802-Target01','Reconcile initiator IDs')) { Set-IscsiServerTarget -TargetName 'AZ802-Target01' -InitiatorIds $InitiatorId | Out-Null }
}
$Mapped=@(Get-IscsiVirtualDisk -TargetName 'AZ802-Target01' -ErrorAction SilentlyContinue | Where-Object Path -eq $Path)
if ($Mapped.Count -eq 0 -and $PSCmdlet.ShouldProcess($Path,'Map virtual disk to target')) { Add-IscsiVirtualDiskTargetMapping -TargetName 'AZ802-Target01' -Path $Path }
Get-IscsiServerTarget -TargetName 'AZ802-Target01'; Get-IscsiVirtualDisk -TargetName 'AZ802-Target01'
