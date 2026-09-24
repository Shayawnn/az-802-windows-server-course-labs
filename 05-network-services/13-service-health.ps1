#Requires -Version 5.1
<#
.SYNOPSIS
Module 5 | Network-service health

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Reports installed roles, service state and the TCP/UDP listeners that correspond to the course services.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | Network-service health'

# Step 1: Report installed service roles without assuming they all exist.
Write-Az802Step 1 'Inspect role and service state'
$Features = Get-WindowsFeature DNS,DHCP,Web-Server
$Features | Select-Object DisplayName,Name,Installed
foreach ($ServiceName in @('DNS','DHCPServer','TermService','W3SVC')) {
    $Service = Get-Service $ServiceName -ErrorAction SilentlyContinue
    if ($Service) { $Service | Select-Object Name,Status,StartType }
    else { Write-Az802Status SKIP ('Service not installed: {0}' -f $ServiceName) }
}

# Step 2: Report local listeners using the protocol each service actually uses.
Write-Az802Step 2 'Inspect common listeners'
foreach ($Port in 53,80,443,3389) {
    $Listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
    if ($Listener) { Write-Az802Status OK ('TCP/{0} is listening.' -f $Port) }
    else { Write-Az802Status INFO ('No TCP listener on {0}.' -f $Port) }
}
foreach ($Port in 53,67) {
    $Listener = Get-NetUDPEndpoint -LocalPort $Port -ErrorAction SilentlyContinue
    if ($Listener) { Write-Az802Status OK ('UDP/{0} is listening.' -f $Port) }
    else { Write-Az802Status INFO ('No UDP listener on {0}.' -f $Port) }
}

# Step 3: Run role-specific cmdlets only when available.
Write-Az802Step 3 'Run role-specific checks when available'
if (Test-Az802Command Get-DnsServerZone) { Get-DnsServerZone }
if (Test-Az802Command Get-DhcpServerv4Scope) { Get-DhcpServerv4Scope }
if (Test-Az802Command Get-Website) { Get-Website; Get-WebBinding }
