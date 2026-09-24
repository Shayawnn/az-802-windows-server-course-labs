#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Windows NFS client

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Client for NFS installation and mounting an explicit export are opt-in.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [string]$Server,
    [string]$ExportName,
    [ValidatePattern('^[D-Zd-z]$')][string]$DriveLetter = 'Z'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | Windows NFS client'
# Step 1: Inspect or install Client for NFS.
Write-Az802Step 1 'Inspect Windows NFS client state'
$Role=Get-WindowsFeature NFS-Client
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install Client for NFS')) { Install-WindowsFeature NFS-Client | Out-Host }
if (-not (Get-WindowsFeature NFS-Client).Installed) { Write-Az802Status SKIP 'Client for NFS is not installed.'; return }

# Step 2: Mount an explicit export only when requested and the drive letter is free.
Write-Az802Step 2 'Optional NFS mount'
if ($Server -and $ExportName) {
    $Drive=('{}:'.Replace('{}',$DriveLetter))
    if (Test-Path $Drive) { throw ('Drive {0} is already in use.' -f $Drive) }
    $Remote='{0}:/{1}' -f $Server,$ExportName
    if ($PSCmdlet.ShouldProcess($Remote,('Mount on {0}' -f $Drive))) { Invoke-Az802Native -FilePath 'mount.exe' -ArgumentList @($Remote,$Drive) | Out-Null }
    Get-ChildItem ($Drive+'\') -ErrorAction Continue
} elseif ($Server -or $ExportName) { throw 'Supply -Server and -ExportName together.' }
