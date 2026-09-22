#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 2 | Group Policy baseline

.RUN ON
A domain-joined Windows Server with Group Policy and Active Directory management tools.

.SAFE TO RERUN
Yes

.CHANGES
Creates the AZ802-Server-Baseline GPO and links it only to the AZ802-Servers OU.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | Group Policy baseline'

$Context = Get-Az802DomainContext
if (-not $Context.PartOfDomain) { Write-Az802Status SKIP 'The current server is not domain joined.'; return }
if (-not (Test-Az802Command Get-GPO) -or -not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'Group Policy/Active Directory management tools are not available.'; return }
Import-Module GroupPolicy
Import-Module ActiveDirectory
$Domain = Get-ADDomain -ErrorAction Stop
$TargetOu = 'OU=AZ802-Servers,{0}' -f $Domain.DistinguishedName
if (-not (Get-ADOrganizationalUnit -Identity $TargetOu -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP 'AZ802-Servers OU does not exist. Run 03-domain-baseline.ps1 first.'; return }
$GpoName = 'AZ802-Server-Baseline'

# Step 1: Create or verify the course GPO.
Write-Az802Step 1 'Create or verify the course GPO'
$Gpo = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue
if ($Gpo) {
    Write-Az802Status OK ('GPO exists: {0}' -f $GpoName)
} elseif ($PSCmdlet.ShouldProcess($GpoName,'Create GPO')) {
    $Gpo = New-GPO -Name $GpoName -Comment 'AZ-802 course baseline'
    Write-Az802Status CREATE ('Created GPO: {0}' -f $GpoName)
}

# Step 2: Create or verify the link to the course Servers OU.
Write-Az802Step 2 'Create or verify the GPO link'
$Inheritance = Get-GPInheritance -Target $TargetOu
$Linked = $Inheritance.GpoLinks | Where-Object DisplayName -eq $GpoName
if ($Linked) {
    Write-Az802Status OK ('GPO is linked to {0}.' -f $TargetOu)
} elseif ($PSCmdlet.ShouldProcess($TargetOu,('Link {0}' -f $GpoName))) {
    New-GPLink -Name $GpoName -Target $TargetOu -LinkEnabled Yes | Out-Null
    Write-Az802Status CREATE ('Linked {0} to {1}.' -f $GpoName,$TargetOu)
}
Get-GPInheritance -Target $TargetOu | Select-Object -ExpandProperty GpoLinks
