#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | Remote Desktop

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. -Enable turns on RDP, requires NLA and enables the built-in firewall rules.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Enable
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | Remote Desktop'
# Step 1: Read current RDP service, listener and firewall state.
Write-Az802Step 1 'Inspect Remote Desktop state'
Get-Service TermService
Get-NetTCPConnection -LocalPort 3389 -State Listen -ErrorAction SilentlyContinue
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue | Select-Object DisplayName,Enabled,Direction,Action

# Step 2: Enable RDP with NLA only when requested.
Write-Az802Step 2 'Optional RDP enablement'
if ($Enable) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Enable Remote Desktop with NLA')) {
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
        Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
    }
}

# Step 3: Read recent RDP-related events.
Write-Az802Step 3 'Read recent RDP events'
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625;StartTime=(Get-Date).AddHours(-6)} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated,Id,Message
Get-WinEvent -LogName 'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational' -MaxEvents 20 -ErrorAction SilentlyContinue | Select-Object TimeCreated,Id,Message
