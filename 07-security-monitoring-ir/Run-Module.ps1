#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Safe course path

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Scripts with destructive or environment-specific actions require explicit parameters and are not included in the default runner.

.CHANGES
Runs the module scripts that are safe with their default parameters.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Safe course path'
$Scripts = @(
    '12-course-health-check.ps1',
    '01-updates-defender-firewall.ps1',
    '04-auditing-and-events.ps1',
    '05-performance-and-network.ps1',
    '06-ad-troubleshooting.ps1',
    '11-windows-event-forwarding.ps1',
    '14-openssh-security.ps1',
    '15-protected-users-and-vbs.ps1'
)

$Index = 0
foreach ($ScriptName in $Scripts) {
    $Index++
    Write-Az802Step $Index ("Run {0}" -f $ScriptName)
    $Path = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Az802Status FAIL ("Missing script: {0}" -f $Path)
        throw "Module runner is incomplete."
    }
    & $Path
}

Write-Az802Status OK 'Module runner completed the safe/default path.'
