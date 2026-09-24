#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Storage and file-service health

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only. Reports disks, volumes, SMB sessions, optional storage roles, recent storage events and the backup catalog.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | Storage and file-service health'
# Step 1: Inspect local storage and SMB state.
Write-Az802Step 1 'Inspect disks, volumes and SMB'
Get-Disk
Get-Volume
Get-SmbShare
Get-SmbSession -ErrorAction SilentlyContinue
Get-SmbOpenFile -ErrorAction SilentlyContinue

# Step 2: Run optional-role health commands only when their modules are available.
Write-Az802Step 2 'Inspect optional storage roles'
if (Test-Az802Command Get-NfsShare) { Get-NfsShare }
if (Test-Az802Command Get-IscsiServerTarget) { Get-IscsiServerTarget }
if (Test-Az802Command Get-DfsnRoot) { Get-DfsnRoot -ErrorAction SilentlyContinue }
if (Test-Az802Command Get-DfsReplicationGroup) { Get-DfsReplicationGroup -ErrorAction SilentlyContinue }

# Step 3: Read recent relevant storage/system warnings and backup catalog.
Write-Az802Step 3 'Read recent storage and backup signals'
Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue | Where-Object { $_.LevelDisplayName -in @('Error','Warning') -and $_.ProviderName -match 'disk|ntfs|stor|vol|smb|dfsr|nfs|iscsi' } | Select-Object -First 30 TimeCreated,Id,ProviderName,Message
if (Get-Command wbadmin.exe -ErrorAction SilentlyContinue) { Invoke-Az802Native -FilePath 'wbadmin.exe' -ArgumentList @('get','versions') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null }
