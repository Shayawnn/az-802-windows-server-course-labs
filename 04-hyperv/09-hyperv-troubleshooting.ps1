#Requires -Version 5.1
<#
.SYNOPSIS
Module 4 | Hyper-V troubleshooting

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Reports Hyper-V host, VM, switch, event and service state.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VMName
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | Hyper-V troubleshooting'
# Step 1: Check the host role and management service.
Write-Az802Step 1 'Check Hyper-V host state'
Get-WindowsFeature Hyper-V
Get-Service vmms -ErrorAction SilentlyContinue
Get-WinEvent -LogName System -MaxEvents 30 | Where-Object LevelDisplayName -in @('Error','Warning') | Select-Object TimeCreated,Id,ProviderName,Message

# Step 2: Check storage and virtual networking without assuming a VM exists.
Write-Az802Step 2 'Check Hyper-V storage and networking'
Get-Volume
Get-VMSwitch -ErrorAction SilentlyContinue
Get-NetNat -ErrorAction SilentlyContinue
if ($VMName -and (Get-VM -Name $VMName -ErrorAction SilentlyContinue)) {
    Get-VM -Name $VMName | Select-Object Name,State,Status
    Get-VMNetworkAdapter -VMName $VMName
    Get-VMHardDiskDrive -VMName $VMName
    Get-VMSnapshot -VMName $VMName -ErrorAction SilentlyContinue
    if ((Get-VM -Name $VMName).Generation -eq 2) { Get-VMFirmware -VMName $VMName }
}
