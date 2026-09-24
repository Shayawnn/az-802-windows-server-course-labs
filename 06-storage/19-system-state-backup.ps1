#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | System state backup

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Windows Server Backup installation is explicit. System-state backup requires an explicit target and -Run.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [string]$BackupTarget,
    [switch]$Run
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | System state backup'

# Step 1: Inspect or install Windows Server Backup.
Write-Az802Step 1 'Inspect Windows Server Backup state'
$Role = Get-WindowsFeature Windows-Server-Backup
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install Windows Server Backup')) { Install-WindowsFeature Windows-Server-Backup | Out-Host }
if (-not (Get-WindowsFeature Windows-Server-Backup).Installed -or -not (Test-Az802Command wbadmin.exe)) { Write-Az802Status SKIP 'Windows Server Backup is not installed. Rerun with -Install if you want to add it.'; return }

# Step 2: Require a real explicit backup target.
Write-Az802Step 2 'Validate system-state backup target'
if (-not $BackupTarget) { Write-Az802Status INFO 'Supply -BackupTarget explicitly, for example E: or a supported backup destination.'; return }
if (-not $Run) { Write-Az802Status INFO ('Target selected: {0}. Supply -Run to start the backup.' -f $BackupTarget); return }

# Step 3: Start the system-state backup.
Write-Az802Step 3 'Start system-state backup'
if ($PSCmdlet.ShouldProcess($BackupTarget,'Start system-state backup')) { Invoke-Az802Native -FilePath 'wbadmin.exe' -ArgumentList @('start','systemstatebackup',('-backupTarget:{0}' -f $BackupTarget),'-quiet') | Out-Null }
Invoke-Az802Native -FilePath 'wbadmin.exe' -ArgumentList @('get','versions') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null
