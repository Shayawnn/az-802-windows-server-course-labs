#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Controlled containment

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. One explicit containment action is applied at a time; identity and connectivity guardrails are enforced.

.CHANGES
Performs an explicitly selected containment action after target validation.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('None','DisableLocalUser','DisableADUser','BlockInboundPort','DisableAdapter')][string]$Action = 'None',
    [string]$Name,
    [ValidateRange(1,65535)][int]$Port,
    [string]$AdapterName,
    [switch]$AllowNonCourseIdentity,
    [switch]$IUnderstandConnectivityLoss
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Controlled containment'
# Step 1: Show current candidates before containment.
Write-Az802Step 1 'Review requested containment target'
if (-not $Action -or $Action -eq 'None') { Write-Az802Status INFO 'No containment action requested.'; return }

# Step 2: Apply one explicit, reversible or well-scoped containment action.
Write-Az802Step 2 ('Containment action: {0}' -f $Action)
switch ($Action) {
 'DisableLocalUser' {
    if (Test-Az802IsDomainController) { Write-Az802Status SKIP 'Local-user containment is not applicable on a domain controller.'; return }
    if (-not (Test-Az802Command Get-LocalUser)) { Write-Az802Status SKIP 'Local account cmdlets are not available on this host.'; return }
    if (-not $Name) { throw 'Supply -Name.' }
    if (-not (Test-Az802CourseName $Name) -and -not $AllowNonCourseIdentity) { throw 'Refusing a non-AZ802 local identity without -AllowNonCourseIdentity.' }
    $U=Get-LocalUser -Name $Name -ErrorAction Stop; $U
    if ($PSCmdlet.ShouldProcess($Name,'Disable local user')) { Disable-LocalUser -Name $Name }
 }
 'DisableADUser' {
    if (-not (Test-Az802Command Get-ADUser)) { Write-Az802Status SKIP 'Active Directory PowerShell tools are not available.'; return }
    if (-not (Get-Az802DomainContext).PartOfDomain) { Write-Az802Status SKIP 'This host is not joined to an Active Directory domain.'; return }
    if (-not $Name) { throw 'Supply -Name.' }
    if (-not (Test-Az802CourseName $Name) -and -not $AllowNonCourseIdentity) { throw 'Refusing a non-AZ802 AD identity without -AllowNonCourseIdentity.' }
    Import-Module ActiveDirectory; $U=Get-ADUser -Identity $Name -ErrorAction Stop; $U
    if ($PSCmdlet.ShouldProcess($Name,'Disable AD user')) { Disable-ADAccount -Identity $U }
 }
 'BlockInboundPort' {
    if (-not $Port) { throw 'Supply -Port.' }
    $Rule='AZ802-Contain-Block-{0}' -f $Port
    $Existing=Get-NetFirewallRule -Name $Rule -ErrorAction SilentlyContinue
    if ($Existing) {
        $Filter=$Existing|Get-NetFirewallPortFilter
        if ($Filter.Protocol -ne 'TCP' -or [string]$Filter.LocalPort -ne [string]$Port) { throw 'Course containment rule exists with unexpected semantics.' }
    } elseif ($PSCmdlet.ShouldProcess($Rule,('Block inbound TCP/{0}' -f $Port))) { New-NetFirewallRule -Name $Rule -DisplayName ('AZ802 | Temporary containment block TCP {0}' -f $Port) -Direction Inbound -Protocol TCP -LocalPort $Port -Action Block | Out-Null }
 }
 'DisableAdapter' {
    if (-not $AdapterName) { throw 'Supply -AdapterName explicitly.' }
    $Adapter=Get-NetAdapter -Name $AdapterName -ErrorAction Stop; $Adapter
    if (-not $IUnderstandConnectivityLoss) { throw 'Supply -IUnderstandConnectivityLoss before disabling a network adapter.' }
    if ($PSCmdlet.ShouldProcess($AdapterName,'Disable network adapter')) { Disable-NetAdapter -Name $AdapterName -Confirm:$false }
 }
}
