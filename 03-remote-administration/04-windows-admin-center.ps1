#Requires -Version 5.1
<#
.SYNOPSIS
Module 3 | Windows Admin Center checks

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Reports Windows Admin Center services, listeners and matching firewall rules when present.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 3 | Windows Admin Center checks'
# Step 1: Look for Windows Admin Center services.
Write-Az802Step 1 'Inspect Windows Admin Center services'
$Services = Get-Service | Where-Object DisplayName -Like '*Windows Admin Center*'
if ($Services) { $Services | Select-Object Name,DisplayName,Status,StartType }
else { Write-Az802Status INFO 'No Windows Admin Center service was found on this server.' }

# Step 2: Inspect listening ports and matching firewall rules.
Write-Az802Step 2 'Inspect listeners and firewall rules'
Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object LocalAddress,LocalPort,OwningProcess
Get-NetFirewallRule | Where-Object DisplayName -Like '*Windows Admin Center*' | Select-Object DisplayName,Enabled,Direction,Action
