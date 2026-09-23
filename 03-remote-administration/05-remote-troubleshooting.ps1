#Requires -Version 5.1
<#
.SYNOPSIS
Module 3 | Remote administration troubleshooting

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Runs local troubleshooting commands and optional reachability checks against an explicit remote host.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ComputerName
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 3 | Remote administration troubleshooting'
$Config = Import-Az802Config -RepoRoot $RepoRoot

# Step 1: Show local network, DNS and WinRM state.
Write-Az802Step 1 'Inspect local network and WinRM state'
Get-NetAdapter
Get-NetIPConfiguration
Get-DnsClientServerAddress
Get-Service WinRM
try { Test-WSMan localhost | Out-Host } catch { Write-Az802Status WARN $_.Exception.Message }

# Step 2: Run ordered peer checks only when a separate target exists.
Write-Az802Step 2 'Optional peer troubleshooting'
if (-not $ComputerName) { $ComputerName = $Config.PeerWindowsHost }
if (-not $ComputerName) { Write-Az802Status SKIP 'No peer Windows host is configured.'; return }
Resolve-DnsName $ComputerName -ErrorAction Continue
Test-Connection $ComputerName -Count 2 -ErrorAction Continue
Test-NetConnection $ComputerName -Port 5985
try { Test-WSMan $ComputerName -ErrorAction Stop | Out-Host; Write-Az802Status OK 'WSMan responds.' } catch { Write-Az802Status WARN $_.Exception.Message }
