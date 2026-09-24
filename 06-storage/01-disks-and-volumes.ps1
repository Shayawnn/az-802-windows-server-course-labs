#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Disks and volumes

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. No disk is selected automatically. Boot/system and non-RAW disks are refused.

.CHANGES
Read-only by default. Initializes and formats only an explicitly selected RAW non-system disk.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [int]$DiskNumber,
    [ValidatePattern('^[D-Zd-z]$')][char]$DriveLetter = 'E',
    [string]$Label = 'AZ802-Data'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | Disks and volumes'
# Step 1: Inventory storage before touching any disk.
Write-Az802Step 1 'Inspect disks and volumes'
Get-Disk
Get-Partition
Get-Volume
Get-PhysicalDisk
Get-StoragePool
Get-VirtualDisk

# Step 2: Initialize only an explicit RAW non-system disk.
Write-Az802Step 2 'Optional disk initialization'
if (-not $PSBoundParameters.ContainsKey('DiskNumber')) { Write-Az802Status INFO 'Supply -DiskNumber explicitly to initialize a new lab disk. No disk number is guessed.'; return }
$Disk=Get-Disk -Number $DiskNumber -ErrorAction Stop
if ($Disk.IsBoot -or $Disk.IsSystem) { throw 'Refusing to initialize a boot/system disk.' }
if ($Disk.PartitionStyle -ne 'RAW') { Write-Az802Status SKIP ('Disk {0} is not RAW; current partition style is {1}.' -f $DiskNumber,$Disk.PartitionStyle); return }
if (Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue) { throw ('Drive letter {0}: is already in use. Choose another drive letter.' -f $DriveLetter) }
if ($PSCmdlet.ShouldProcess(('Disk {0}' -f $DiskNumber),('Initialize and format as {0}:' -f $DriveLetter))) {
    Initialize-Disk -Number $DiskNumber -PartitionStyle GPT
    $Partition=New-Partition -DiskNumber $DiskNumber -UseMaximumSize -DriveLetter $DriveLetter
    Format-Volume -Partition $Partition -FileSystem NTFS -NewFileSystemLabel $Label -Confirm:$false | Out-Null
}
Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
