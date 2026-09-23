#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 3 | Safe course path

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
Write-Az802Header 'Module 3 | Safe course path'
$Scripts = @(
    '01-powershell-administration.ps1',
    '04-windows-admin-center.ps1',
    '05-remote-troubleshooting.ps1',
    '06-powershell-discovery-and-profile.ps1',
    '07-feature-and-service-operations.ps1',
    '08-azure-vm-reference.ps1'
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
