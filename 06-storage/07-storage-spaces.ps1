#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Storage Spaces

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. A new storage pool is never built from every poolable disk automatically; its physical disks must be selected by UniqueId.

.CHANGES
Read-only by default. Course pool creation requires explicit physical-disk UniqueIds. Formatting is separately explicit.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Create,
    [string[]]$PhysicalDiskUniqueId,
    [ValidateRange(1073741824,10995116277760)][uint64]$Size = 20GB,
    [ValidatePattern('^[D-Zd-z]$')][char]$DriveLetter
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | Storage Spaces'

# Step 1: Inspect poolable disks and the existing course pool.
Write-Az802Step 1 'Inspect Storage Spaces candidates'
$Poolable = @(Get-PhysicalDisk -CanPool $true)
$Poolable | Select-Object FriendlyName,UniqueId,SerialNumber,MediaType,Size,CanPool
$Pool = Get-StoragePool -FriendlyName 'AZ802-LabPool' -ErrorAction SilentlyContinue
if ($Pool) { $Pool | Select-Object FriendlyName,HealthStatus,OperationalStatus,Size,AllocatedSize }
if (-not $Create) { Write-Az802Status INFO 'Use -Create. If the course pool does not exist, also supply at least two -PhysicalDiskUniqueId values from the candidate list.'; return }

# Step 2: Create the course pool from explicit physical disks, then create or verify the mirror virtual disk.
Write-Az802Step 2 'Create or verify course Storage Spaces objects'
if (-not $Pool) {
    if (-not $PhysicalDiskUniqueId -or $PhysicalDiskUniqueId.Count -lt 2) { Write-Az802Status SKIP 'A new mirror pool requires at least two explicit -PhysicalDiskUniqueId values. No disk was selected automatically.'; return }
    $Selected = @()
    foreach ($Id in $PhysicalDiskUniqueId) {
        $Disk = $Poolable | Where-Object UniqueId -eq $Id | Select-Object -First 1
        if (-not $Disk) { throw ('Requested physical disk is not currently poolable or was not found: {0}' -f $Id) }
        $Selected += $Disk
    }
    if (($Selected.UniqueId | Select-Object -Unique).Count -ne $PhysicalDiskUniqueId.Count) { throw 'PhysicalDiskUniqueId contains duplicate selections.' }
    if ($PSCmdlet.ShouldProcess('AZ802-LabPool',('Create storage pool from {0} explicitly selected disks' -f $Selected.Count))) {
        $Pool = New-StoragePool -FriendlyName 'AZ802-LabPool' -StorageSubsystemFriendlyName 'Windows Storage*' -PhysicalDisks $Selected
    }
    $Pool = Get-StoragePool -FriendlyName 'AZ802-LabPool' -ErrorAction SilentlyContinue
    if (-not $Pool) { Write-Az802Status INFO 'Storage-pool creation was not performed.'; return }
}
$Vd = Get-VirtualDisk -FriendlyName 'AZ802-LabMirror' -ErrorAction SilentlyContinue
if ($Vd -and $Vd.StoragePoolUniqueId -ne $Pool.UniqueId) { throw 'AZ802-LabMirror exists but is not in AZ802-LabPool.' }
if (-not $Vd -and $PSCmdlet.ShouldProcess('AZ802-LabMirror','Create mirror virtual disk')) { $Vd = New-VirtualDisk -StoragePoolFriendlyName 'AZ802-LabPool' -FriendlyName 'AZ802-LabMirror' -Size $Size -ResiliencySettingName Mirror }
$Vd = Get-VirtualDisk -FriendlyName 'AZ802-LabMirror' -ErrorAction SilentlyContinue
Get-StoragePool -FriendlyName 'AZ802-LabPool'
$Vd
if (-not $Vd) { return }

# Step 3: Initialize the virtual disk only when a free drive letter is explicitly requested and the backing disk is RAW.
Write-Az802Step 3 'Optional virtual-disk formatting'
if ($DriveLetter) {
    if (Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue) { throw ('Drive letter {0}: is already in use.' -f $DriveLetter) }
    $Disk = $Vd | Get-Disk
    if ($Disk.PartitionStyle -eq 'RAW' -and $PSCmdlet.ShouldProcess(('Disk {0}' -f $Disk.Number),('Format as {0}:' -f $DriveLetter))) {
        Initialize-Disk -Number $Disk.Number -PartitionStyle GPT
        $Part = New-Partition -DiskNumber $Disk.Number -UseMaximumSize -DriveLetter $DriveLetter
        Format-Volume -Partition $Part -FileSystem NTFS -NewFileSystemLabel 'AZ802-StorageSpace' -Confirm:$false | Out-Null
    } elseif ($Disk.PartitionStyle -ne 'RAW') { Write-Az802Status INFO 'Virtual disk already has a partition table; it was not reformatted.' }
}
