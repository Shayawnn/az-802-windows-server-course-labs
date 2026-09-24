#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | Safe course path

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
Write-Az802Header 'Module 4 | Safe course path'
$Scripts = @(
    '01-install-hyperv.ps1',
    '02-virtual-networking.ps1',
    '09-hyperv-troubleshooting.ps1'
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
