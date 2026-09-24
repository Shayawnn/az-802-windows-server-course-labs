#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Safe course path

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
Write-Az802Header 'Module 6 | Safe course path'
$Scripts = @(
    '12-storage-health.ps1',
    '01-disks-and-volumes.ps1',
    '02-smb-and-ntfs.ps1',
    '03-fsrm.ps1',
    '04-nfs-server.ps1',
    '05-iscsi-target.ps1',
    '06-iscsi-initiator.ps1',
    '07-storage-spaces.ps1',
    '08-dfs-namespace.ps1',
    '09-dfs-replication.ps1',
    '10-backup.ps1',
    '14-failover-clustering.ps1'
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
