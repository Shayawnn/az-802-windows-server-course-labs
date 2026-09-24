#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | Nested virtualization

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Nested-virtualization changes require -Enable and an offline VM.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VMName = 'AZ802-WIN01',
    [switch]$Enable
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | Nested virtualization'
# Step 1: Require an existing course VM and show its current processor/network state.
Write-Az802Step 1 'Inspect nested-virtualization prerequisites'
$VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if (-not $VM) { Write-Az802Status SKIP ('VM not found: {0}' -f $VMName); return }
Get-VMProcessor -VMName $VMName | Select-Object VMName,Count,ExposeVirtualizationExtensions
Get-VMNetworkAdapter -VMName $VMName | Select-Object VMName,Name,MacAddressSpoofing,SwitchName
if (-not $Enable) { Write-Az802Status INFO 'Use -Enable to expose virtualization extensions and enable MAC spoofing.'; return }
if ($VM.State -ne 'Off') { Write-Az802Status SKIP 'Nested-virtualization processor settings require the VM to be off.'; return }

# Step 2: Change only settings that are not already correct.
Write-Az802Step 2 'Enable nested virtualization settings'
$Processor = Get-VMProcessor -VMName $VMName
if (-not $Processor.ExposeVirtualizationExtensions -and $PSCmdlet.ShouldProcess($VMName,'Expose virtualization extensions')) { Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true }
$Adapters = Get-VMNetworkAdapter -VMName $VMName
foreach ($Adapter in $Adapters) {
    if ($Adapter.MacAddressSpoofing -ne 'On' -and $PSCmdlet.ShouldProcess($VMName,('Enable MAC spoofing on {0}' -f $Adapter.Name))) { Set-VMNetworkAdapter -VMName $VMName -Name $Adapter.Name -MacAddressSpoofing On }
}
Get-VMProcessor -VMName $VMName | Select-Object VMName,ExposeVirtualizationExtensions
Get-VMNetworkAdapter -VMName $VMName | Select-Object Name,MacAddressSpoofing
