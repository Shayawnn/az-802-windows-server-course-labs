#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 3 | Features and services

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Feature and service changes require explicit parameters.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$FeatureName,
    [ValidateSet('None','Install','Remove')][string]$FeatureAction = 'None',
    [string]$RestartService
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 3 | Features and services'
# Step 1: Inspect selected Windows features.
Write-Az802Step 1 'Inspect common course features'
Get-WindowsFeature -Name AD-Domain-Services,DNS,DHCP,Web-Server,Hyper-V | Select-Object DisplayName,Name,Installed

# Step 2: Install or remove one explicit feature when requested.
Write-Az802Step 2 'Optional feature operation'
if ($FeatureName) {
    $Feature = Get-WindowsFeature -Name $FeatureName -ErrorAction Stop
    if ($FeatureAction -eq 'Install' -and -not $Feature.Installed -and $PSCmdlet.ShouldProcess($FeatureName,'Install feature')) { Install-WindowsFeature -Name $FeatureName -IncludeManagementTools | Out-Host }
    elseif ($FeatureAction -eq 'Remove' -and $Feature.Installed -and $PSCmdlet.ShouldProcess($FeatureName,'Remove feature')) { Remove-WindowsFeature -Name $FeatureName | Out-Host }
    else { Write-Az802Status INFO 'Requested feature state already matches, or no change action was selected.' }
}

# Step 3: Inspect common administration services.
Write-Az802Step 3 'Inspect services'
Get-Service -Name WinRM,TermService,W32Time,EventLog -ErrorAction SilentlyContinue | Select-Object Name,DisplayName,Status,StartType
if ($RestartService) {
    if ($PSCmdlet.ShouldProcess($RestartService,'Restart service')) { Restart-Service -Name $RestartService -ErrorAction Stop; Get-Service $RestartService }
}
