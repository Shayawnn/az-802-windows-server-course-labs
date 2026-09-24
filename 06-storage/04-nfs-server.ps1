#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | NFS server

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. NFS installation and creation of the AZ802-NFS01 course share are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [switch]$CreateShare
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | NFS server'
# Step 1: Inspect or install Server for NFS.
Write-Az802Step 1 'Inspect NFS Server state'
$Role=Get-WindowsFeature FS-NFS-Service
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install Server for NFS')) { Install-WindowsFeature FS-NFS-Service -IncludeManagementTools | Out-Host }
if (-not (Get-WindowsFeature FS-NFS-Service).Installed) { Write-Az802Status SKIP 'Server for NFS is not installed.'; return }
Get-NfsServerConfiguration

# Step 2: Create or verify the course NFS share.
Write-Az802Step 2 'Optional course NFS share'
if ($CreateShare) {
    $Path='C:\AZ802\NFS\NFS01'; Initialize-Az802Directory -Path $Path
    $Existing=Get-NfsShare -Name 'AZ802-NFS01' -ErrorAction SilentlyContinue
    if ($Existing -and $Existing.Path -ne $Path) { throw 'AZ802-NFS01 exists with an unexpected path.' }
    if (-not $Existing -and $PSCmdlet.ShouldProcess('AZ802-NFS01','Create NFS share')) { New-NfsShare -Name 'AZ802-NFS01' -Path $Path -Authentication sys -Permission readwrite -AllowRootAccess $false | Out-Null }
    Get-NfsShare -Name 'AZ802-NFS01'; Get-NfsSharePermission -Name 'AZ802-NFS01'
}
