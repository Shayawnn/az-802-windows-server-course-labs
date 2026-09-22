#Requires -Version 5.1
<#
.SYNOPSIS
Module 1 | Inventory and preflight

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Inventories the current Windows Server before any configuration changes are made.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 1 | Inventory and preflight'
# Step 1: Collect operating-system and identity facts.
Write-Az802Step 1 'Read operating system and computer identity'
Get-ComputerInfo | Select-Object WindowsProductName,WindowsVersion,OsHardwareAbstractionLayer,CsName,CsDomain,CsPartOfDomain

# Step 2: Read network and DNS state.
Write-Az802Step 2 'Read network and DNS state'
Get-NetIPConfiguration
Get-DnsClientServerAddress -AddressFamily IPv4

# Step 3: Read time-service state without treating a non-synchronized workgroup server as a script failure.
Write-Az802Step 3 'Read Windows Time state'
Invoke-Az802Native -FilePath 'w32tm.exe' -ArgumentList @('/query','/status') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null

# Step 4: List local users only when the local SAM is applicable.
Write-Az802Step 4 'Read local account state'
if (Test-Az802IsDomainController) { Write-Az802Status SKIP 'This machine is a domain controller; local SAM users are not used on a DC.' }
else { Get-LocalUser | Select-Object Name,Enabled,LastLogon }
