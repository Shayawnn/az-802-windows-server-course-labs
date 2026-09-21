#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Environment preparation

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Runs a read-only preflight by default. Desktop tools, Sysinternals and Ubuntu media are installed/downloaded only through explicit switches.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$InstallDesktopTools,
    [switch]$IncludeSysinternals,
    [switch]$DownloadUbuntuIso
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Environment preparation'
# Step 1: Run the environment preflight.
Write-Az802Step 1 'Run environment preflight'
& (Join-Path $PSScriptRoot '01-preflight.ps1')

# Step 2: Install optional desktop tools.
Write-Az802Step 2 'Handle classroom desktop tools'
if ($InstallDesktopTools) { & (Join-Path $PSScriptRoot '02-install-desktop-tools.ps1') }
else { Write-Az802Status SKIP 'Desktop-tool installation was not requested.' }

# Step 3: Install optional Sysinternals tools.
Write-Az802Step 3 'Handle Sysinternals Suite'
if ($IncludeSysinternals) { & (Join-Path $PSScriptRoot '03-install-sysinternals.ps1') }
else { Write-Az802Status SKIP 'Sysinternals installation was not requested.' }

# Step 4: Download optional lab media.
Write-Az802Step 4 'Handle optional lab media'
if ($DownloadUbuntuIso) { & (Join-Path $PSScriptRoot '04-download-lab-media.ps1') -DownloadUbuntu }
else { Write-Az802Status SKIP 'Ubuntu ISO download was not requested.' }
