#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 2 | GPO registry setting and policy refresh

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Optionally configures an AZ802 GPO and refreshes policy on the current machine.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$SetRdpPolicy,
    [switch]$RefreshLocalComputer
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | GPO registry setting and policy refresh'
if (-not (Test-Az802Command Get-GPO)) { Write-Az802Status SKIP 'Group Policy management tools are not available on this machine.'; return }
Import-Module GroupPolicy
$GpoName = 'AZ802-Server-Baseline'

# Step 1: Set the course GPO registry value only when the course GPO exists.
Write-Az802Step 1 'Configure the course GPO setting'
if (-not (Get-GPO -Name $GpoName -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP ('GPO not found: {0}. Run 04-group-policy.ps1 first.' -f $GpoName); return }
if ($SetRdpPolicy -and $PSCmdlet.ShouldProcess($GpoName,'Set RDP policy value')) {
    Set-GPRegistryValue -Name $GpoName -Key 'HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services' -ValueName fDenyTSConnections -Type DWord -Value 0
}

# Step 2: Refresh and report policy on the current computer when requested.
Write-Az802Step 2 'Optional local policy refresh and report'
if ($RefreshLocalComputer) {
    Initialize-Az802Directory -Path 'C:\AZ802\Reports'
    Invoke-Az802Native -FilePath 'gpupdate.exe' -ArgumentList @('/force') -AllowedExitCodes @(0) | Out-Null
    Invoke-Az802Native -FilePath 'gpresult.exe' -ArgumentList @('/r') -AllowedExitCodes @(0) | Out-Null
    $Report = 'C:\AZ802\Reports\gpresult.html'
    Invoke-Az802Native -FilePath 'gpresult.exe' -ArgumentList @('/h',$Report,'/f') -AllowedExitCodes @(0) | Out-Null
    if (Test-Path $Report) { Write-Az802Status OK ('Generated {0}' -f $Report) }
}
