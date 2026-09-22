#Requires -Version 5.1
<#
.SYNOPSIS
Module 2 | Active Directory health

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Reports domain-controller, replication and DNS diagnostics when the current machine is a domain controller.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | Active Directory health'
$Context = Get-Az802DomainContext
if (-not $Context.PartOfDomain) { Write-Az802Status SKIP 'This machine is not domain joined.'; return }

if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'The Active Directory PowerShell module is not available.'; return }

# Step 1: Run domain discovery queries.
Write-Az802Step 1 'Read domain and domain-controller state'
Import-Module ActiveDirectory
Get-ADDomain
Get-ADForest
Get-ADDomainController -Discover

# Step 2: Run DC-only diagnostics only when this machine is a domain controller.
Write-Az802Step 2 'Run domain-controller diagnostics when applicable'
if (Test-Az802IsDomainController) {
    Invoke-Az802Native -FilePath 'dcdiag.exe' -ArgumentList @('/test:dns','/v') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null
    Invoke-Az802Native -FilePath 'repadmin.exe' -ArgumentList @('/replsummary') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null
} else { Write-Az802Status SKIP 'dcdiag and repadmin checks are reserved for a domain controller.' }

# Step 3: Verify SRV-record discovery against the real domain.
Write-Az802Step 3 'Verify domain service discovery'
Resolve-DnsName ('_ldap._tcp.dc._msdcs.{0}' -f $Context.DnsRoot) -Type SRV -ErrorAction Continue
