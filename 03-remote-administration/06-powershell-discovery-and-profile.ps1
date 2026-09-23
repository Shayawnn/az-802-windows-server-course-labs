#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 3 | PowerShell discovery and profile

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Execution-policy change is opt-in.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$SetRemoteSigned
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 3 | PowerShell discovery and profile'
# Step 1: Discover commands and modules.
Write-Az802Step 1 'Discover commands'
Get-Command -Noun Service | Select-Object Name,CommandType,Source
Get-Command -Module ServerManager | Select-Object -First 20 Name,CommandType
Get-Help Get-Service -Examples
Get-Service -Name WinRM | Get-Member

# Step 2: Inspect execution policy without changing it by default.
Write-Az802Step 2 'Inspect execution policy'
Get-ExecutionPolicy -List
if ($SetRemoteSigned -and $PSCmdlet.ShouldProcess('LocalMachine execution policy','Set RemoteSigned')) { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine }

# Step 3: Inspect the current profile safely.
Write-Az802Step 3 'Inspect the current PowerShell profile'
Write-Az802Status INFO ('Profile path: {0}' -f $PROFILE)
if (Test-Path $PROFILE) { Get-Item $PROFILE; Get-Content $PROFILE }
else { Write-Az802Status INFO 'No profile file exists for this shell yet.' }
