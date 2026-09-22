#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 1 | Firewall and Remote Desktop

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. -EnableRdp enables RDP, requires NLA and enables the built-in RDP firewall group.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$EnableRdp
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 1 | Firewall and Remote Desktop'
# Step 1: Read the current Remote Desktop state.
Write-Az802Step 1 'Read Remote Desktop state'
$TsPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
$RdpTcpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
$Deny = (Get-ItemProperty -Path $TsPath -Name fDenyTSConnections).fDenyTSConnections
$Nla = (Get-ItemProperty -Path $RdpTcpPath -Name UserAuthentication).UserAuthentication
Write-Az802Status INFO ('RDP allowed: {0}; NLA required: {1}' -f ($Deny -eq 0),($Nla -eq 1))

# Step 2: Enable RDP and Network Level Authentication only when requested.
Write-Az802Step 2 'Optional RDP enablement'
if ($EnableRdp) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Enable RDP with NLA')) {
        Set-ItemProperty -Path $TsPath -Name fDenyTSConnections -Value 0
        Set-ItemProperty -Path $RdpTcpPath -Name UserAuthentication -Value 1
        Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
        Write-Az802Status OK 'Remote Desktop enabled with NLA. Existing access policy still controls who may sign in.'
    }
} else { Write-Az802Status INFO 'Use -EnableRdp to change state.' }

# Step 3: Verify the listener locally.
Write-Az802Step 3 'Verify TCP/3389 listener state'
Get-NetTCPConnection -LocalPort 3389 -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess
