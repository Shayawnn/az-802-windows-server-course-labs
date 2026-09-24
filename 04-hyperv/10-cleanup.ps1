#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | Hyper-V course cleanup

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Only AZ802-prefixed Hyper-V objects are eligible for removal, and removal requires -Remove.

.CHANGES
Optionally removes AZ802-prefixed VMs, NATs and virtual switches.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | Hyper-V course cleanup'
# Step 1: Show course-owned Hyper-V objects before removal.
Write-Az802Step 1 'Inspect course-owned Hyper-V objects'
$VMs = Get-VM -ErrorAction SilentlyContinue | Where-Object Name -Like 'AZ802-*'
$Switches = Get-VMSwitch -ErrorAction SilentlyContinue | Where-Object Name -Like 'AZ802-*'
$Nats = Get-NetNat -ErrorAction SilentlyContinue | Where-Object Name -Like 'AZ802-*'
$VMs | Select-Object Name,State,Path
$Switches | Select-Object Name,SwitchType
$Nats | Select-Object Name,InternalIPInterfaceAddressPrefix
if (-not $Remove) { Write-Az802Status INFO 'Use -Remove to delete only AZ802-prefixed Hyper-V objects.'; return }

# Step 2: Remove course VMs, NATs and switches in dependency order.
Write-Az802Step 2 'Remove course-owned Hyper-V objects'
foreach ($VM in $VMs) {
    if ($VM.State -ne 'Off' -and $PSCmdlet.ShouldProcess($VM.Name,'Stop VM')) { Stop-VM -Name $VM.Name -TurnOff -Force }
    if ($PSCmdlet.ShouldProcess($VM.Name,'Remove VM registration')) { Remove-VM -Name $VM.Name -Force }
}
foreach ($Nat in $Nats) { if ($PSCmdlet.ShouldProcess($Nat.Name,'Remove NAT')) { Remove-NetNat -Name $Nat.Name -Confirm:$false } }
foreach ($Switch in $Switches) { if ($PSCmdlet.ShouldProcess($Switch.Name,'Remove VMSwitch')) { Remove-VMSwitch -Name $Switch.Name -Force } }
Write-Az802Status OK 'Course-owned Hyper-V objects were processed.'
