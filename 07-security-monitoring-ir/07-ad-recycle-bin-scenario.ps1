#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | AD Recycle Bin scenario

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Forest-wide enablement requires explicit acknowledgement. Object operations are restricted to AZ802-RecycleBinDemo.

.CHANGES
Optionally enables AD Recycle Bin and runs a course-scoped delete/restore scenario.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$EnableFeature,
    [switch]$IUnderstandForestWideChange,
    [ValidateSet('Build','Delete','Restore','Verify')][string]$Phase = 'Verify'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | AD Recycle Bin scenario'
if (-not (Test-Az802Command Get-ADForest)) { Write-Az802Status SKIP 'Active Directory PowerShell tools are not available.'; return }
$Context = Get-Az802DomainContext
if (-not $Context.PartOfDomain) { Write-Az802Status SKIP 'This scenario requires an Active Directory forest.'; return }
Import-Module ActiveDirectory
$Forest=Get-ADForest -ErrorAction Stop
$Name='AZ802-RecycleBinDemo'
# Step 1: Inspect Recycle Bin feature state.
Write-Az802Step 1 'Inspect AD Recycle Bin state'
$Feature=Get-ADOptionalFeature -Filter 'Name -eq "Recycle Bin Feature"'
$Enabled=$Feature.EnabledScopes.Count -gt 0
Write-Az802Status INFO ('Recycle Bin enabled: {0}' -f $Enabled)

# Step 2: Enable the forest-wide feature only with explicit acknowledgement.
Write-Az802Step 2 'Optional forest-wide Recycle Bin enablement'
if ($EnableFeature -and -not $Enabled) {
    if (-not $IUnderstandForestWideChange) { throw 'Supply -IUnderstandForestWideChange before enabling AD Recycle Bin.' }
    if ($PSCmdlet.ShouldProcess($Forest.Name,'Enable AD Recycle Bin')) { Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $Forest.Name -Confirm:$false }
}
if (-not ((Get-ADOptionalFeature -Filter 'Name -eq "Recycle Bin Feature"').EnabledScopes.Count -gt 0)) { Write-Az802Status SKIP 'Recycle Bin is not enabled; delete/restore demonstration is skipped.'; return }

# Step 3: Create/delete/restore only the AZ802 demo user.
Write-Az802Step 3 ('Scenario phase: {0}' -f $Phase)
switch ($Phase) {
 'Build' { if (-not (Get-ADUser -Identity $Name -ErrorAction SilentlyContinue) -and $PSCmdlet.ShouldProcess($Name,'Create disabled demo user')) { New-ADUser -Name $Name -SamAccountName $Name -Enabled $false } }
 'Delete' { $U=Get-ADUser -Identity $Name -ErrorAction SilentlyContinue; if ($U -and $PSCmdlet.ShouldProcess($Name,'Delete demo user')) { Remove-ADUser $U -Confirm:$false } }
 'Restore' { $Deleted=Get-ADObject -Filter ('samAccountName -eq "{0}"' -f $Name) -IncludeDeletedObjects; if ($Deleted -and $PSCmdlet.ShouldProcess($Name,'Restore demo user')) { $Deleted|Restore-ADObject } }
 'Verify' { Get-ADUser -Identity $Name -ErrorAction SilentlyContinue; Get-ADObject -Filter ('samAccountName -eq "{0}"' -f $Name) -IncludeDeletedObjects -ErrorAction SilentlyContinue }
}
