#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | iSCSI initiator

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. No target or disk is guessed. A connection requires an explicit target node address; RAW disk initialization requires an explicit disk number.

.CHANGES
Optionally starts MSiSCSI, registers an explicit portal, connects one explicit target and initializes one explicit RAW iSCSI disk.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Prepare,
    [string]$TargetPortalAddress,
    [string]$TargetNodeAddress,
    [switch]$Connect,
    [int]$DiskNumber
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | iSCSI initiator'

# Step 1: Inspect and optionally prepare the Microsoft iSCSI Initiator service.
Write-Az802Step 1 'Inspect iSCSI initiator state'
$Service = Get-Service MSiSCSI -ErrorAction Stop
$Service
if ($Prepare -and ($Service.Status -ne 'Running' -or $Service.StartType -ne 'Automatic') -and $PSCmdlet.ShouldProcess('MSiSCSI','Set Automatic and start')) {
    Set-Service MSiSCSI -StartupType Automatic
    Start-Service MSiSCSI
    $Service = Get-Service MSiSCSI
}
if ($Service.Status -eq 'Running') { Get-InitiatorPort -ErrorAction SilentlyContinue }
elseif ($TargetPortalAddress -or $Connect) { Write-Az802Status SKIP 'MSiSCSI is not running. Rerun with -Prepare before creating a portal or connecting a target.'; return }

# Step 2: Register an explicit portal and optionally connect one explicit target.
Write-Az802Step 2 'Optional target portal and connection'
if ($TargetPortalAddress) {
    $Portal = Get-IscsiTargetPortal -ErrorAction SilentlyContinue | Where-Object TargetPortalAddress -eq $TargetPortalAddress | Select-Object -First 1
    if (-not $Portal -and $PSCmdlet.ShouldProcess($TargetPortalAddress,'Create iSCSI target portal')) { New-IscsiTargetPortal -TargetPortalAddress $TargetPortalAddress | Out-Null }
}
$Targets = @(Get-IscsiTarget -ErrorAction SilentlyContinue)
$Targets | Select-Object NodeAddress,IsConnected
if ($Connect) {
    if (-not $TargetNodeAddress) { Write-Az802Status SKIP 'Supply -TargetNodeAddress from the displayed target list. The script will not connect every discovered target.' }
    else {
        $Target = $Targets | Where-Object NodeAddress -eq $TargetNodeAddress | Select-Object -First 1
        if (-not $Target) { throw ('Target node was not discovered: {0}' -f $TargetNodeAddress) }
        if ($Target.IsConnected) { Write-Az802Status OK ('Target is already connected: {0}' -f $TargetNodeAddress) }
        elseif ($PSCmdlet.ShouldProcess($TargetNodeAddress,'Connect iSCSI target persistently')) { Connect-IscsiTarget -NodeAddress $TargetNodeAddress -IsPersistent $true | Out-Null }
    }
}

# Step 3: Initialize only an explicitly selected RAW iSCSI disk.
Write-Az802Step 3 'Optional iSCSI disk initialization'
if ($PSBoundParameters.ContainsKey('DiskNumber')) {
    $Disk = Get-Disk -Number $DiskNumber -ErrorAction Stop
    if ($Disk.IsBoot -or $Disk.IsSystem) { throw 'Refusing boot/system disk.' }
    if ($Disk.PartitionStyle -ne 'RAW') { Write-Az802Status SKIP ('Disk {0} is not RAW; current partition style is {1}.' -f $DiskNumber,$Disk.PartitionStyle); return }
    if ($Disk.BusType -ne 'iSCSI') { throw ('Selected disk bus type is {0}, not iSCSI.' -f $Disk.BusType) }
    if ($PSCmdlet.ShouldProcess(('Disk {0}' -f $DiskNumber),'Initialize iSCSI lab disk')) {
        Initialize-Disk -Number $DiskNumber -PartitionStyle GPT
        $Part = New-Partition -DiskNumber $DiskNumber -UseMaximumSize -AssignDriveLetter
        Format-Volume -Partition $Part -FileSystem NTFS -NewFileSystemLabel 'AZ802-iSCSI' -Confirm:$false | Out-Null
    }
}
Get-IscsiConnection -ErrorAction SilentlyContinue
Get-Disk
