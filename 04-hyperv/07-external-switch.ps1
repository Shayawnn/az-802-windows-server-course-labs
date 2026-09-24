#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | External Hyper-V switch

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. The physical NIC is never guessed. Creation requires -Create and an explicit adapter name.

.CHANGES
Optionally creates a course-scoped external Hyper-V switch.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Create,
    [string]$SwitchName = 'AZ802-External',
    [string]$NetAdapterName,
    [switch]$IUnderstandConnectivityImpact
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | External Hyper-V switch'
# Step 1: Show physical adapters and existing external switches.
Write-Az802Step 1 'Inspect physical adapters and external switches'
Get-NetAdapter | Select-Object Name,InterfaceDescription,Status,LinkSpeed
Get-VMSwitch | Where-Object SwitchType -eq External | Select-Object Name,NetAdapterInterfaceDescription
if (-not $Create) { Write-Az802Status INFO 'Use -Create and -NetAdapterName to create an external switch.'; return }
if (-not $NetAdapterName) { throw 'Supply -NetAdapterName explicitly. The script will not guess which physical NIC may be disrupted.' }
if (-not $IUnderstandConnectivityImpact) { throw 'Creating an external switch can briefly disrupt the host network. Rerun with -IUnderstandConnectivityImpact after confirming you can recover the session if connectivity drops.' }
$Adapter = Get-NetAdapter -Name $NetAdapterName -ErrorAction Stop
$ExistingBinding = Get-VMSwitch | Where-Object { $_.SwitchType -eq 'External' -and $_.NetAdapterInterfaceDescription -eq $Adapter.InterfaceDescription }
if ($ExistingBinding -and $ExistingBinding.Name -ne $SwitchName) { throw ('Adapter {0} is already bound to external switch {1}.' -f $NetAdapterName,$ExistingBinding.Name) }
$Existing = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if ($Existing) { Write-Az802Status OK ('Switch already exists: {0}' -f $SwitchName); return }

# Step 2: Create the requested switch with management OS access preserved by default.
Write-Az802Step 2 'Create the external switch'
if ($PSCmdlet.ShouldProcess($NetAdapterName,('Create external VMSwitch {0}' -f $SwitchName))) {
    New-VMSwitch -Name $SwitchName -NetAdapterName $NetAdapterName -AllowManagementOS $true | Out-Null
}
Get-VMSwitch -Name $SwitchName
