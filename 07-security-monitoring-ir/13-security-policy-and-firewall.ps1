#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Security policy and firewall

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Evidence export and course-scoped firewall rule creation are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$ExportPolicy,
    [ValidateRange(1,65535)][int]$Port
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Security policy and firewall'
# Step 1: Export the current local security policy and Group Policy result when requested.
Write-Az802Step 1 'Optional security-policy evidence export'
if ($ExportPolicy) {
    $Dir='C:\AZ802\Reports'; Initialize-Az802Directory -Path $Dir
    Invoke-Az802Native 'secedit.exe' @('/export','/cfg',(Join-Path $Dir 'security-policy.inf')) @(0) | Out-Null
    Invoke-Az802Native 'gpresult.exe' @('/r') @(0) -WarnOnly | Out-Null
    Invoke-Az802Native 'gpresult.exe' @('/h',(Join-Path $Dir 'gpresult.html'),'/f') @(0) -WarnOnly | Out-Null
}

# Step 2: Create one course-scoped inbound rule only when an explicit port is supplied.
Write-Az802Step 2 'Optional course firewall rule'
if ($Port) {
    $RuleName='AZ802-Allow-TCP-{0}' -f $Port
    $Existing=Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
    if (-not $Existing -and $PSCmdlet.ShouldProcess($RuleName,('Allow inbound TCP/{0}' -f $Port))) { New-NetFirewallRule -Name $RuleName -DisplayName ('AZ802 | Allow TCP {0}' -f $Port) -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null }
    Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
}
