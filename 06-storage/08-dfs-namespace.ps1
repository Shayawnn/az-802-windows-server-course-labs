#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | DFS Namespace

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Creates only an AZ802 domain namespace and validates existing root/folder targets before reuse.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [switch]$Create,
    [string]$FolderTarget
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | DFS Namespace'

# Step 1: Inspect or install DFS Namespace tools.
Write-Az802Step 1 'Inspect DFS Namespace state'
$Role = Get-WindowsFeature FS-DFS-Namespace
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install DFS Namespace')) { Install-WindowsFeature FS-DFS-Namespace -IncludeManagementTools | Out-Host }
if (-not (Get-WindowsFeature FS-DFS-Namespace).Installed) { Write-Az802Status SKIP 'DFS Namespace is not installed.'; return }
if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'Active Directory PowerShell tools are not available. A domain namespace requires Active Directory.'; return }
$Domain = Get-ADDomain -ErrorAction SilentlyContinue
if (-not $Domain) { Write-Az802Status SKIP 'A domain namespace requires this server to have access to an Active Directory domain.'; return }
if (-not $Create) { Get-DfsnRoot -ErrorAction SilentlyContinue; Write-Az802Status INFO 'Use -Create only after the underlying SMB targets exist.'; return }

# Step 2: Create or verify the namespace root share and domain namespace.
Write-Az802Step 2 'Create or verify the course namespace root'
$RootPath = '\\{0}\AZ802-Files' -f $Domain.DNSRoot
$RootShare = 'AZ802-FilesRoot'
$RootLocal = 'C:\AZ802\DFS\FilesRoot'
Initialize-Az802Directory -Path $RootLocal
$Administrators = Get-Az802AccountNameBySid -Sid 'S-1-5-32-544'
$Share = Get-SmbShare -Name $RootShare -ErrorAction SilentlyContinue
if (-not $Share -and $PSCmdlet.ShouldProcess($RootShare,'Create namespace root SMB share')) { New-SmbShare -Name $RootShare -Path $RootLocal -FullAccess $Administrators | Out-Null }
$Share = Get-SmbShare -Name $RootShare -ErrorAction SilentlyContinue
if (-not $Share) { Write-Az802Status INFO 'Namespace root share creation was not performed.'; return }
if ($Share.Path -ne $RootLocal) { throw 'Namespace root share exists with an unexpected path.' }
$Target = '\\{0}\{1}' -f $env:COMPUTERNAME,$RootShare
$Root = Get-DfsnRoot -Path $RootPath -ErrorAction SilentlyContinue
if (-not $Root -and $PSCmdlet.ShouldProcess($RootPath,'Create domain DFS namespace')) { New-DfsnRoot -Path $RootPath -TargetPath $Target -Type DomainV2 | Out-Null }
$Root = Get-DfsnRoot -Path $RootPath -ErrorAction SilentlyContinue
if (-not $Root) { Write-Az802Status INFO 'DFS namespace creation was not performed.'; return }
$Targets = @(Get-DfsnRootTarget -Path $RootPath -ErrorAction SilentlyContinue).TargetPath
if ($Targets -notcontains $Target) { throw 'DFS root exists but does not include the expected course target.' }

# Step 3: Add one optional Public folder target only when explicitly supplied.
Write-Az802Step 3 'Optional namespace folder target'
if ($FolderTarget) {
    if ($FolderTarget -notlike '\\*' -and -not (Test-Path -LiteralPath $FolderTarget)) { throw 'FolderTarget must exist locally or be a valid UNC path.' }
    $FolderPath = $RootPath + '\Public'
    $Folder = Get-DfsnFolder -Path $FolderPath -ErrorAction SilentlyContinue
    if (-not $Folder -and $PSCmdlet.ShouldProcess($FolderPath,('Create DFS folder target {0}' -f $FolderTarget))) { New-DfsnFolder -Path $FolderPath -TargetPath $FolderTarget | Out-Null }
    $Folder = Get-DfsnFolder -Path $FolderPath -ErrorAction SilentlyContinue
    if ($Folder) {
        $FolderTargets = @(Get-DfsnFolderTarget -Path $FolderPath -ErrorAction SilentlyContinue).TargetPath
        if ($FolderTargets -notcontains $FolderTarget) { throw 'DFS folder exists but points somewhere else.' }
    }
}
Get-DfsnRoot -Path $RootPath
