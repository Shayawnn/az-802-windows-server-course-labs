#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Backup recovery

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Recovery requires a real version identifier and explicit source item; nothing is guessed.

.CHANGES
Lists backup versions and optionally restores explicit file items to a course recovery directory. A non-local backup catalog can be addressed with -BackupTarget.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$BackupTarget,
    [string]$Version,
    [string]$Items,
    [string]$RecoveryTarget = 'C:\AZ802\Restore',
    [switch]$Recover
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | Backup recovery'
if (-not (Test-Az802Command wbadmin.exe)) { Write-Az802Status SKIP 'wbadmin.exe is not available. Install Windows Server Backup before using this lab.'; return }

# Step 1: Show backup versions before accepting a recovery version.
Write-Az802Step 1 'List available backup versions'
$VersionArgs = @('get','versions')
if ($BackupTarget) { $VersionArgs += ('-backupTarget:{0}' -f $BackupTarget) }
Invoke-Az802Native -FilePath 'wbadmin.exe' -ArgumentList $VersionArgs -AllowedExitCodes @(0,1) -WarnOnly | Out-Null
if (-not $Version) { Write-Az802Status INFO 'Supply -Version exactly as shown by wbadmin get versions. The script will not invent or guess a backup version.'; return }
if (-not $Items) { throw 'Supply -Items for file recovery.' }
Initialize-Az802Directory -Path $RecoveryTarget

# Step 2: Show the selected backup contents before recovery.
Write-Az802Step 2 'Inspect the selected backup version'
$ItemArgs = @('get','items',('-version:{0}' -f $Version))
if ($BackupTarget) { $ItemArgs += ('-backupTarget:{0}' -f $BackupTarget) }
Invoke-Az802Native -FilePath 'wbadmin.exe' -ArgumentList $ItemArgs -AllowedExitCodes @(0) | Out-Null

# Step 3: Recover only when explicitly requested.
Write-Az802Step 3 'Optional file recovery'
if ($Recover -and $PSCmdlet.ShouldProcess($Items,('Recover to {0}' -f $RecoveryTarget))) {
    $RecoveryArgs = @('start','recovery',('-version:{0}' -f $Version),'-itemType:File',('-items:{0}' -f $Items),('-recoveryTarget:{0}' -f $RecoveryTarget),'-quiet')
    if ($BackupTarget) { $RecoveryArgs += ('-backupTarget:{0}' -f $BackupTarget) }
    Invoke-Az802Native -FilePath 'wbadmin.exe' -ArgumentList $RecoveryArgs | Out-Null
}
