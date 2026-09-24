#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Windows Server Backup

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspects the backup catalog by default. Backup creation requires explicit target and source path.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [string]$BackupTarget,
    [string]$IncludePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | Windows Server Backup'
# Step 1: Inspect or install Windows Server Backup.
Write-Az802Step 1 'Inspect Windows Server Backup state'
$Role=Get-WindowsFeature Windows-Server-Backup
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install Windows Server Backup')) { Install-WindowsFeature Windows-Server-Backup | Out-Host }
if (-not (Get-WindowsFeature Windows-Server-Backup).Installed) { Write-Az802Status SKIP 'Windows Server Backup is not installed.'; return }

# Step 2: List existing backup versions without treating an empty catalog as a script crash.
Write-Az802Step 2 'Read backup catalog'
Invoke-Az802Native -FilePath 'wbadmin.exe' -ArgumentList @('get','versions') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null

# Step 3: Run a one-time backup only to an explicit target.
Write-Az802Step 3 'Optional one-time backup'
if ($BackupTarget -and $IncludePath) {
    if (-not (Test-Path -LiteralPath $IncludePath)) { throw ('Include path does not exist: {0}' -f $IncludePath) }
    if ($PSCmdlet.ShouldProcess($IncludePath,('Back up to {0}' -f $BackupTarget))) { Invoke-Az802Native -FilePath 'wbadmin.exe' -ArgumentList @('start','backup',('-backupTarget:{0}' -f $BackupTarget),('-include:{0}' -f $IncludePath),'-quiet') | Out-Null }
} elseif ($BackupTarget -or $IncludePath) { throw 'Supply -BackupTarget and -IncludePath together.' }
