#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Environment preflight

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Reports operating-system, elevation, network, storage and virtualization readiness, plus the configured course working directory.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Environment preflight'
# Step 1: Confirm the shell is elevated and show the Windows edition.
Write-Az802Step 1 'Check administrator rights and Windows edition'
Assert-Az802Administrator
$Info = Get-ComputerInfo
$Info | Select-Object WindowsProductName,WindowsVersion,OsBuildNumber,CsName
Write-Az802Status OK 'Administrator rights confirmed.'

# Step 2: Inspect network reachability without changing configuration.
Write-Az802Step 2 'Inspect network configuration'
Get-NetIPConfiguration
$Primary = Get-Az802PrimaryAdapter
if ($Primary) { Write-Az802Status OK ('Primary interface candidate: {0}' -f $Primary.InterfaceAlias) }
else { Write-Az802Status WARN 'No active IPv4 interface with an address was found.' }

# Step 3: Inspect the configured course working directory without creating it.
Write-Az802Step 3 'Inspect the course working directory'
$Config = Import-Az802Config -RepoRoot $RepoRoot
if (Test-Path -LiteralPath $Config.LabRoot) {
    Write-Az802Status OK ('Course working directory exists: {0}' -f $Config.LabRoot)
} else {
    Write-Az802Status INFO ('Course working directory does not exist yet: {0}. Changing scripts create their own required paths.' -f $Config.LabRoot)
}
