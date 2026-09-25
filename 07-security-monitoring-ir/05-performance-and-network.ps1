#Requires -Version 5.1
<#
.SYNOPSIS
Module 7 | Performance and network troubleshooting

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Samples current performance, process, network and service state.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Target
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Performance and network troubleshooting'
# Step 1: Inspect listening TCP ports and owning processes.
Write-Az802Step 1 'Inspect listening ports'
$Connections=@(Get-NetTCPConnection -State Listen | Sort-Object LocalPort)
$Connections | Select-Object LocalAddress,LocalPort,OwningProcess
$Connection=$Connections | Select-Object -First 1
if ($Connection) { Get-Process -Id $Connection.OwningProcess -ErrorAction SilentlyContinue | Select-Object Name,Id,Path }

# Step 2: Collect counters that exist on this machine.
Write-Az802Step 2 'Read available performance counters'
$Candidates=@('\Processor(_Total)\% Processor Time','\Memory\Available MBytes','\PhysicalDisk(_Total)\Avg. Disk sec/Read','\Network Interface(*)\Bytes Total/sec')
foreach ($Counter in $Candidates) {
    try { Get-Counter $Counter -MaxSamples 1 -ErrorAction Stop | Out-Host }
    catch { Write-Az802Status WARN ('Counter unavailable on this installation/localization: {0}' -f $Counter) }
}
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name,Id,CPU,WorkingSet64

# Step 3: Test an optional target without assuming a particular server name.
Write-Az802Step 3 'Optional target connectivity checks'
if ($Target) { Resolve-DnsName $Target -ErrorAction Continue; foreach ($Port in 80,443,445,3389,5985) { Test-NetConnection $Target -Port $Port -WarningAction SilentlyContinue | Select-Object ComputerName,RemotePort,TcpTestSucceeded } }
