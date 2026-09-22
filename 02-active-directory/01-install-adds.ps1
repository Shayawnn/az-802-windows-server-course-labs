#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 2 | Install AD DS

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Installs AD DS only with -Install.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | Install AD DS'
# Step 1: Inspect the AD DS role.
Write-Az802Step 1 'Inspect AD DS role state'
$Role = Get-WindowsFeature AD-Domain-Services
$Role
if ($Role.Installed) { Write-Az802Status OK 'AD DS role is already installed.'; return }

# Step 2: Install AD DS only when requested.
Write-Az802Step 2 'Optional AD DS installation'
if (-not $Install) { Write-Az802Status INFO 'Use -Install to install AD DS and its management tools.'; return }
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install AD DS')) {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Get-WindowsFeature AD-Domain-Services,RSAT-AD-Tools
}
