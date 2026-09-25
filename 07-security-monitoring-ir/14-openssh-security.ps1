#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | OpenSSH security

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspection by default. Explicit setup reuses the tested Module 3 OpenSSH implementation.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$InstallServer,
    [switch]$ConfigureServer,
    [string]$TargetUser,
    [string]$PublicKey
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | OpenSSH security'
# Step 1: Inspect OpenSSH without changing service state.
Write-Az802Step 1 'Inspect OpenSSH security state'
Get-WindowsCapability -Online | Where-Object Name -Like 'OpenSSH*' | Select-Object Name,State
Get-Service sshd -ErrorAction SilentlyContinue
Get-NetFirewallRule -Name 'AZ802-OpenSSH-22' -ErrorAction SilentlyContinue

# Step 2: Reuse Module 3 setup only when an explicit installation/configuration action is requested.
Write-Az802Step 2 'Optional secure OpenSSH setup'
$SetupScript=Join-Path $RepoRoot '03-remote-administration\03-openssh.ps1'
if ($InstallServer -or $ConfigureServer -or $PublicKey) { & $SetupScript -InstallServer:$InstallServer -ConfigureServer:$ConfigureServer -TargetUser $TargetUser -PublicKey $PublicKey }
else { Write-Az802Status INFO 'No OpenSSH state change requested.' }
