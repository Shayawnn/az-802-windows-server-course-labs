#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Active Directory troubleshooting

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Reads AD state and diagnostics. Policy refresh/report is opt-in.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$RefreshPolicy
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Active Directory troubleshooting'
$Context=Get-Az802DomainContext
if (-not $Context.PartOfDomain) { Write-Az802Status SKIP 'This machine is not domain joined.'; return }
if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'Active Directory PowerShell tools are not available on this machine.'; return }
Import-Module ActiveDirectory

# Step 1: Read domain/FSMO state from any domain-joined administration machine.
Write-Az802Step 1 'Read domain and FSMO state'
Get-ADForest | Select-Object SchemaMaster,DomainNamingMaster
Get-ADDomain | Select-Object PDCEmulator,RIDMaster,InfrastructureMaster
Get-ADDomainController -Filter * | Select-Object HostName,Site,IPv4Address,OperatingSystem

# Step 2: Run DC-specific native diagnostics only on a domain controller.
Write-Az802Step 2 'Run DC diagnostics when applicable'
if (Test-Az802IsDomainController) {
    Invoke-Az802Native 'dcdiag.exe' @('/v') @(0,1) -WarnOnly | Out-Null
    Invoke-Az802Native 'repadmin.exe' @('/replsummary') @(0,1) -WarnOnly | Out-Null
    Invoke-Az802Native 'repadmin.exe' @('/showrepl') @(0,1) -WarnOnly | Out-Null
    Invoke-Az802Native 'dcdiag.exe' @('/test:dns','/v') @(0,1) -WarnOnly | Out-Null
} else { Write-Az802Status SKIP 'dcdiag/repadmin target-side checks are skipped because the current server is not a domain controller.' }

# Step 3: Refresh Group Policy and create a report only when requested.
Write-Az802Step 3 'Optional Group Policy refresh/report'
if ($RefreshPolicy) {
    Initialize-Az802Directory -Path 'C:\AZ802\Reports'
    Invoke-Az802Native 'gpupdate.exe' @('/force') @(0) | Out-Null
    Invoke-Az802Native 'gpresult.exe' @('/r') @(0,1) -WarnOnly | Out-Null
    $Report = 'C:\AZ802\Reports\gpresult.html'
    Invoke-Az802Native 'gpresult.exe' @('/h',$Report,'/f') @(0,1) -WarnOnly | Out-Null
    if (Test-Path -LiteralPath $Report) { Write-Az802Status OK ('Generated Group Policy report: {0}' -f $Report) } else { Write-Az802Status WARN 'gpresult did not create the HTML report on this machine.' }
}
