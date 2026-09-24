#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | Advanced VM operations

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Advanced settings and resource metering are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VMName = 'AZ802-WIN01',
    [string]$Notes,
    [ValidateSet('Nothing','StartIfRunning','AlwaysStart')][string]$AutomaticStartAction,
    [ValidateSet('TurnOff','Save','ShutDown')][string]$AutomaticStopAction,
    [switch]$Measure,
    [switch]$ResetMeter
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | Advanced VM operations'
$VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if (-not $VM) { Write-Az802Status SKIP ('VM not found: {0}' -f $VMName); return }

# Step 1: Inspect advanced VM configuration.
Write-Az802Step 1 'Inspect advanced VM configuration'
$VM | Select-Object Name,State,Notes,AutomaticStartAction,AutomaticStopAction
Get-VMIntegrationService -VMName $VMName | Select-Object Name,Enabled,PrimaryStatusDescription

# Step 2: Reconcile notes and automatic actions only when explicitly supplied.
Write-Az802Step 2 'Optional advanced VM settings'
$SetArgs = @{}
if ($PSBoundParameters.ContainsKey('Notes') -and $VM.Notes -ne $Notes) { $SetArgs.Notes = $Notes }
if ($PSBoundParameters.ContainsKey('AutomaticStartAction') -and $VM.AutomaticStartAction.ToString() -ne $AutomaticStartAction) { $SetArgs.AutomaticStartAction = $AutomaticStartAction }
if ($PSBoundParameters.ContainsKey('AutomaticStopAction') -and $VM.AutomaticStopAction.ToString() -ne $AutomaticStopAction) { $SetArgs.AutomaticStopAction = $AutomaticStopAction }
if ($SetArgs.Count -gt 0 -and $PSCmdlet.ShouldProcess($VMName,'Change advanced VM settings')) { Set-VM -Name $VMName @SetArgs }
else { Write-Az802Status INFO 'No advanced VM setting change is required.' }

# Step 3: Demonstrate resource metering only when requested.
Write-Az802Step 3 'Optional resource metering'
if ($Measure) {
    Enable-VMResourceMetering -VMName $VMName
    Measure-VM -VMName $VMName
    if ($ResetMeter) { Reset-VMResourceMetering -VMName $VMName }
}
