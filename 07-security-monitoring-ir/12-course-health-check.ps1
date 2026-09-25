#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Course health check

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Collects general server health and role-specific diagnostics when the corresponding role exists.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Course health check'
# Step 1: Collect general health state that is safe on any Windows Server.
Write-Az802Step 1 'Collect general server health'
hostname.exe
Get-ComputerInfo | Select-Object CsName,OsName,OsVersion,WindowsVersion
Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } | Select-Object Name,DisplayName,Status,StartType
Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddHours(-24)} -ErrorAction SilentlyContinue | Where-Object LevelDisplayName -in @('Error','Warning') | Select-Object -First 20 TimeCreated,Id,ProviderName,Message
Get-NetIPConfiguration
Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object LocalAddress,LocalPort,OwningProcess
Get-Volume
if (Test-Az802Command Get-MpComputerStatus) { Get-MpComputerStatus | Select-Object AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated }

# Step 2: Run role-specific checks only when the corresponding role/cmdlet exists.
Write-Az802Step 2 'Run role-specific health checks'
if (Test-Az802IsDomainController) { Invoke-Az802Native 'repadmin.exe' @('/replsummary') @(0,1) -WarnOnly | Out-Null; Invoke-Az802Native 'dcdiag.exe' @('/test:dns','/v') @(0,1) -WarnOnly | Out-Null }
if (Test-Az802Command Get-DnsServerZone) { Get-DnsServerZone }
if (Test-Az802Command Get-DhcpServerv4Scope) { Get-DhcpServerv4Scope }
if (Test-Az802Command Get-SmbShare) { Get-SmbShare; Get-SmbSession -ErrorAction SilentlyContinue; Get-SmbOpenFile -ErrorAction SilentlyContinue }
if (Test-Az802Command Get-VM) { Get-VM; Get-VMHost }
if (Test-Az802Command Get-Website) { Get-Website; Get-WebBinding }
