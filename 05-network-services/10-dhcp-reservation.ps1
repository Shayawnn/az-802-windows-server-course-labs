#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | DHCP reservation

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Creates a DHCP reservation only from explicit real client values.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ScopeId,
    [string]$IPAddress,
    [string]$ClientId
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | DHCP reservation'
if (-not (Test-Az802Command Get-DhcpServerv4Scope)) { Write-Az802Status SKIP 'DHCP Server management tools are not available.'; return }
Import-Module DhcpServer
# Step 1: Require real scope, IP and client identifier values.
Write-Az802Step 1 'Validate reservation inputs'
if (-not ($ScopeId -and $IPAddress -and $ClientId)) { Write-Az802Status SKIP 'Supply -ScopeId, -IPAddress and the real client -ClientId from the target machine.'; return }
if (-not (Test-Az802IPv4Address $ScopeId)) { throw 'ScopeId must be a valid IPv4 network identifier.' }
if (-not (Test-Az802IPv4Address $IPAddress)) { throw 'IPAddress must be a valid IPv4 address.' }
$Scope=Get-DhcpServerv4Scope -ScopeId $ScopeId -ErrorAction Stop
$Existing=Get-DhcpServerv4Reservation -ScopeId $ScopeId -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -eq $IPAddress -or $_.ClientId -eq $ClientId }
if ($Existing) { $Existing; Write-Az802Status OK 'A matching reservation already exists.'; return }
# Step 2: Create the reservation.
Write-Az802Step 2 'Create the reservation'
if ($PSCmdlet.ShouldProcess($IPAddress,('Reserve for client {0}' -f $ClientId))) { Add-DhcpServerv4Reservation -ScopeId $ScopeId -IPAddress $IPAddress -ClientId $ClientId -Description 'AZ-802 lab reservation' | Out-Null }
Get-DhcpServerv4Reservation -ScopeId $ScopeId
