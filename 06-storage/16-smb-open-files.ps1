#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | SMB open files

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. The script never selects an arbitrary open file for closure. FileId and -Close are both required.

.CHANGES
Lists open SMB files and optionally closes one explicit handle.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [uint64]$FileId,
    [switch]$Close
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | SMB open files'
# Step 1: Display open SMB files before selecting anything.
Write-Az802Step 1 'List open SMB files'
$Files=@(Get-SmbOpenFile -ErrorAction SilentlyContinue)
if ($Files.Count -eq 0) { Write-Az802Status SKIP 'No open SMB files are visible.'; return }
$Files | Select-Object FileId,ClientComputerName,ClientUserName,Path

# Step 2: Close only an explicitly supplied FileId after confirmation.
Write-Az802Step 2 'Optional open-file closure'
if (-not $PSBoundParameters.ContainsKey('FileId')) { Write-Az802Status INFO 'Supply -FileId from the table above when you deliberately want to close one handle.'; return }
$Selected=$Files|Where-Object FileId -eq $FileId
if (-not $Selected) { Write-Az802Status SKIP ('FileId {0} is not currently open.' -f $FileId); return }
$Selected | Format-List
if (-not $Close) { Write-Az802Status INFO 'Supply -Close to confirm the selected handle should be closed.'; return }
if ($PSCmdlet.ShouldProcess($Selected.Path,('Close SMB FileId {0}' -f $FileId))) { Close-SmbOpenFile -FileId $FileId -Force }
