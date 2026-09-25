#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Windows Event Forwarding prerequisites

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspection by default. Source/collector prerequisite changes require an explicit role.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('None','Source','Collector')][string]$Role = 'None'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Windows Event Forwarding prerequisites'
# Step 1: Inspect source/collector services without changing them.
Write-Az802Step 1 'Inspect WEF supporting services'
Get-Service WinRM,Wecsvc -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType

# Step 2: Configure the current machine only for the explicitly requested role.
Write-Az802Step 2 'Optional WEF prerequisite configuration'
if ($Role -eq 'Source') { if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Run winrm quickconfig')) { Invoke-Az802Native 'winrm.cmd' @('quickconfig','-quiet') @(0,1) -WarnOnly | Out-Null } }
elseif ($Role -eq 'Collector') { if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Run wecutil qc')) { Invoke-Az802Native 'wecutil.exe' @('qc','/q:true') @(0) | Out-Null } }
else { Write-Az802Status INFO 'Supply -Role Source or -Role Collector to change configuration.' }
Get-Service WinRM,Wecsvc -ErrorAction SilentlyContinue
