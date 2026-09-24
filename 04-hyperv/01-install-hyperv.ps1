#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | Install Hyper-V

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Hyper-V installation and restart are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [switch]$Restart
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | Install Hyper-V'
# Step 1: Inspect Hyper-V role and host prerequisites.
Write-Az802Step 1 'Inspect Hyper-V availability'
Get-WindowsFeature -Name Hyper-V,RSAT-Hyper-V-Tools | Select-Object DisplayName,Name,Installed
systeminfo.exe | Select-String -Pattern 'Hyper-V Requirements' -Context 0,4

# Step 2: Install Hyper-V only when requested.
Write-Az802Step 2 'Optional Hyper-V installation'
$Role = Get-WindowsFeature Hyper-V
if ($Role.Installed) { Write-Az802Status OK 'Hyper-V is already installed.' }
elseif ($Install -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install Hyper-V and management tools')) {
    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools | Out-Host
    Write-Az802Status WARN 'Restart Windows before creating or managing virtual machines.'
    if ($Restart) { Restart-Computer -Force }
} elseif (-not $Install) { Write-Az802Status INFO 'Use -Install to install Hyper-V.' }

# Step 3: Verify management service and module after installation.
Write-Az802Step 3 'Verify Hyper-V management components'
Get-Service vmms -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType
Get-Command -Module Hyper-V -ErrorAction SilentlyContinue | Select-Object -First 10 Name
