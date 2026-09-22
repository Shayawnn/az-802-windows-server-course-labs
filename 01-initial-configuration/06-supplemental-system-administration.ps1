#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 1 | Supplemental system administration

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Reads update/system state by default. Course-scoped ICMP and time-peer changes require explicit switches/values.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$EnableIcmp,
    [string]$TimePeer
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 1 | Supplemental system administration'
# Step 1: Review update and identity state.
Write-Az802Step 1 'Review updates and system identity'
Get-Service wuauserv
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10
Get-ComputerInfo | Select-Object OsName,OsVersion,WindowsInstallationType,CsName,CsDomain

# Step 2: Create or verify a course-scoped ICMP rule when requested.
Write-Az802Step 2 'Optional ICMPv4 lab rule'
$RuleName = 'AZ802-Allow-ICMPv4'
if ($EnableIcmp) {
    $Rule = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
    if (-not $Rule -and $PSCmdlet.ShouldProcess($RuleName,'Create inbound ICMPv4 rule')) {
        New-NetFirewallRule -Name $RuleName -DisplayName 'AZ802 | Allow ICMPv4 echo' -Description 'Course lab rule' -Profile Any -Direction Inbound -Action Allow -Protocol ICMPv4 | Out-Null
        Write-Az802Status CREATE 'Created AZ802 ICMPv4 firewall rule.'
    } else { Write-Az802Status OK 'AZ802 ICMPv4 rule already exists.' }
}
Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue | Format-List Name,DisplayName,Enabled,Direction,Action,Profile

# Step 3: Configure a manual time peer only when explicitly requested.
Write-Az802Step 3 'Optional Windows Time configuration'
if ($TimePeer) {
    Invoke-Az802Native -FilePath 'w32tm.exe' -ArgumentList @('/config',('/manualpeerlist:{0}' -f $TimePeer),'/syncfromflags:manual','/reliable:no','/update') | Out-Null
    Restart-Service w32time
    Invoke-Az802Native -FilePath 'w32tm.exe' -ArgumentList @('/resync') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null
}
Invoke-Az802Native -FilePath 'w32tm.exe' -ArgumentList @('/query','/status') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null
