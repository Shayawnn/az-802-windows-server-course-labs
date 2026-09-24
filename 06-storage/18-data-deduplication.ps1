#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Data Deduplication

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. No volume is guessed; the system volume is refused.

.CHANGES
Optionally enables/optimizes deduplication on an explicit non-system volume.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [string]$Volume,
    [switch]$Enable,
    [switch]$Optimize
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | Data Deduplication'
# Step 1: Inspect or install Data Deduplication.
Write-Az802Step 1 'Inspect Data Deduplication state'
$Role=Get-WindowsFeature FS-Data-Deduplication
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install Data Deduplication')) { Install-WindowsFeature FS-Data-Deduplication | Out-Host }
if (-not (Get-WindowsFeature FS-Data-Deduplication).Installed) { Write-Az802Status SKIP 'Data Deduplication is not installed.'; return }
Get-DedupStatus -ErrorAction SilentlyContinue
if (-not $Volume) { Write-Az802Status INFO 'Supply -Volume explicitly to enable deduplication. The system volume is never selected automatically.'; return }
if ($Volume.TrimEnd(':') -ieq $env:SystemDrive.TrimEnd(':')) { throw 'Refusing to enable Data Deduplication on the system volume.' }
$VolumeLetter = $Volume.TrimEnd(':')
if ($VolumeLetter -notmatch '^[A-Za-z]$') { throw 'Volume must be supplied as a drive letter such as E:.' }
if (-not (Get-Volume -DriveLetter $VolumeLetter -ErrorAction SilentlyContinue)) { throw ('Volume does not exist: {0}' -f $Volume) }
# Step 2: Enable and optionally optimize an explicit data volume.
Write-Az802Step 2 'Configure the explicit data volume'
$Current=Get-DedupVolume -Volume $Volume -ErrorAction SilentlyContinue
if (-not $Current -and $Enable -and $PSCmdlet.ShouldProcess($Volume,'Enable Data Deduplication')) { Enable-DedupVolume -Volume $Volume -UsageType Default | Out-Null }
if ($Optimize -and $PSCmdlet.ShouldProcess($Volume,'Start deduplication optimization')) { Start-DedupJob -Volume $Volume -Type Optimization | Out-Host }
Get-DedupVolume -Volume $Volume -ErrorAction SilentlyContinue; Get-DedupStatus
