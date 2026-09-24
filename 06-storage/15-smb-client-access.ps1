#Requires -Version 5.1
<#
.SYNOPSIS
Module 6 | SMB client access

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Persistent drive mapping is explicit and only uses an accessible requested SMB path.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Server,
    [string]$ShareName = 'AZ802-Share01',
    [switch]$MapDrive,
    [ValidatePattern('^[D-Zd-z]$')][string]$DriveName = 'Z'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | SMB client access'
$Config=Import-Az802Config -RepoRoot $RepoRoot
if (-not $Server) { $Server=$Config.PeerWindowsHost }
if (-not $Server) { Write-Az802Status SKIP 'No separate SMB server is configured. Use localhost explicitly only when you intentionally want a local share test.'; return }
$Unc='\\{0}\{1}' -f $Server,$ShareName
# Step 1: Test network and UNC access.
Write-Az802Step 1 'Test SMB reachability'
if (-not (Test-Az802TcpPort -ComputerName $Server -Port 445)) { Write-Az802Status SKIP ('TCP/445 is not reachable on {0}.' -f $Server); return }
Write-Az802Status OK ('TCP/445 is reachable on {0}.' -f $Server)
if (-not (Test-Path $Unc)) { Write-Az802Status SKIP ('UNC path is not accessible: {0}' -f $Unc); return }
Get-ChildItem $Unc | Select-Object -First 20

# Step 2: Map a drive only when explicitly requested and conflict-free.
Write-Az802Step 2 'Optional persistent mapped drive'
if ($MapDrive) {
    $Existing=Get-PSDrive -Name $DriveName -ErrorAction SilentlyContinue
    if ($Existing -and $Existing.Root -ne $Unc) { throw ('Drive {0}: already maps to {1}.' -f $DriveName,$Existing.Root) }
    if (-not $Existing -and $PSCmdlet.ShouldProcess(('{0}:' -f $DriveName),('Map to {0}' -f $Unc))) { New-PSDrive -Name $DriveName -PSProvider FileSystem -Root $Unc -Persist | Out-Null }
    Get-PSDrive $DriveName
}
