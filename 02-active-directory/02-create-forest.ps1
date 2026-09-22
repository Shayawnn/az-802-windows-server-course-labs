#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 2 | Create a new forest

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. No promotion happens without -Create. Existing domain membership is detected and forest creation is skipped.

.CHANGES
Optionally creates a new AD DS forest and DNS service.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$DomainName,
    [ValidatePattern('^[A-Za-z0-9-]{1,15}$')][string]$NetBIOSName,
    [Security.SecureString]$SafeModeAdministratorPassword,
    [switch]$Create,
    [switch]$Restart
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | Create a new forest'
# Step 1: Refuse forest creation on a machine that is already domain joined.
Write-Az802Step 1 'Check whether a new forest is appropriate'
$Context = Get-Az802DomainContext
if ($Context.PartOfDomain) { Write-Az802Status SKIP ('Machine already belongs to domain {0}. Forest creation is not appropriate here.' -f $Context.DnsRoot); return }
if (-not (Get-WindowsFeature AD-Domain-Services).Installed) { throw 'Install AD DS first with 01-install-adds.ps1 -Install.' }
$Config = Import-Az802Config -RepoRoot $RepoRoot
if (-not $DomainName) { $DomainName = $Config.DefaultDomainName }
if (-not $NetBIOSName) { $NetBIOSName = $Config.DefaultNetBIOSName }

# Step 2: Show the exact requested forest configuration before changing the server.
Write-Az802Step 2 'Review the requested forest'
Write-Az802Status INFO ('DNS domain: {0}' -f $DomainName)
Write-Az802Status INFO ('NetBIOS name: {0}' -f $NetBIOSName)
if (-not $Create) { Write-Az802Status INFO 'Use -Create when you are ready to promote this server.'; return }

# Step 3: Create the forest and allow the Windows restart boundary to remain explicit.
Write-Az802Step 3 'Create the AD DS forest'
if ($PSCmdlet.ShouldProcess($DomainName,'Install a new AD DS forest')) {
    if (-not $SafeModeAdministratorPassword) { $SafeModeAdministratorPassword = Read-Host 'Directory Services Restore Mode password' -AsSecureString }
    Import-Module ADDSDeployment
    Install-ADDSForest -DomainName $DomainName -DomainNetbiosName $NetBIOSName -SafeModeAdministratorPassword $SafeModeAdministratorPassword -InstallDNS -NoRebootOnCompletion:$true -Force
    Write-Az802Status WARN 'Forest promotion completed. Restart Windows before running the domain-baseline script.'
    if ($Restart) { Restart-Computer -Force }
}
