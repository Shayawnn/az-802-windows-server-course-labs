#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 2 | Domain password policy

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Read-only unless both -Apply and -IUnderstandDomainWideImpact are supplied.

.CHANGES
Optionally changes the default domain password/lockout policy.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Apply,
    [switch]$IUnderstandDomainWideImpact,
    [ValidateRange(0,128)][int]$MinPasswordLength = 12,
    [TimeSpan]$MaxPasswordAge = ([TimeSpan]::FromDays(90)),
    [ValidateRange(0,999)][int]$LockoutThreshold = 5,
    [TimeSpan]$LockoutDuration = ([TimeSpan]::FromMinutes(15))
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | Domain password policy'
$Context = Get-Az802DomainContext
if (-not $Context.PartOfDomain) { Write-Az802Status SKIP 'The current server is not domain joined.'; return }
if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'The Active Directory PowerShell module is not available.'; return }
Import-Module ActiveDirectory
$Domain = Get-ADDomain

# Step 1: Show the effective default domain password policy.
Write-Az802Step 1 'Read current default domain password policy'
Get-ADDefaultDomainPasswordPolicy -Identity $Domain.DNSRoot | Format-List

# Step 2: Apply an explicit policy only after deliberate acknowledgement.
Write-Az802Step 2 'Optional policy change'
if (-not $Apply) { Write-Az802Status INFO 'Use -Apply to change the default domain policy. Review the values first.'; return }
if (-not $IUnderstandDomainWideImpact) { throw 'Supply -IUnderstandDomainWideImpact to confirm this is a domain-wide change.' }
if ($PSCmdlet.ShouldProcess($Domain.DNSRoot,'Change default domain password policy')) {
    Set-ADDefaultDomainPasswordPolicy -Identity $Domain.DNSRoot -MinPasswordLength $MinPasswordLength -MaxPasswordAge $MaxPasswordAge -LockoutThreshold $LockoutThreshold -LockoutDuration $LockoutDuration
}
Get-ADDefaultDomainPasswordPolicy -Identity $Domain.DNSRoot | Format-List
