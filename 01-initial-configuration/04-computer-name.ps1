#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 1 | Computer name

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. A rename is only attempted when -NewName is supplied. A restart is opt-in.

.CHANGES
Optionally renames the current computer.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidatePattern('^[A-Za-z0-9-]{1,15}$')][string]$NewName,
    [switch]$Restart
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 1 | Computer name'
# Step 1: Show the current name.
Write-Az802Step 1 'Show the current computer name'
Write-Az802Status INFO ('Current name: {0}' -f $env:COMPUTERNAME)

# Step 2: Rename only when an explicit new name is supplied.
Write-Az802Step 2 'Optional rename'
if (-not $NewName) { Write-Az802Status SKIP 'No new computer name supplied.'; return }
if ($env:COMPUTERNAME -ieq $NewName) { Write-Az802Status OK 'Computer already has the requested name.'; return }
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,('Rename to {0}' -f $NewName))) {
    Rename-Computer -NewName $NewName -Force -PassThru
    Write-Az802Status WARN 'Restart Windows before continuing with labs that depend on the new computer name.'
    if ($Restart) { Restart-Computer -Force }
}
