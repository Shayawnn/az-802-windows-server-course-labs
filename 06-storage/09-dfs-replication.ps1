#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | DFS Replication

.RUN ON
One of two Windows Server DFS Replication members

.SAFE TO RERUN
Yes. If no distinct peer exists, the script skips. Existing course memberships are validated before reuse.

.CHANGES
Optionally creates a two-server AZ802 DFS Replication group after explicit peer validation.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$PeerComputerName,
    [PSCredential]$PeerCredential,
    [switch]$Create
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | DFS Replication'
$Config = Import-Az802Config -RepoRoot $RepoRoot
if (-not $PeerComputerName) { $PeerComputerName = $Config.PeerWindowsHost }

# Step 1: Require a real second Windows Server before doing anything.
Write-Az802Step 1 'Resolve the second DFS Replication member'
if (-not $PeerComputerName) { Write-Az802Status SKIP 'No peer Windows Server is configured. DFS Replication requires two servers.'; return }
$PeerShortName = ($PeerComputerName -split '\.')[0]
if ($PeerComputerName -in @('localhost','127.0.0.1','::1','.') -or $PeerShortName -ieq $env:COMPUTERNAME) { Write-Az802Status SKIP 'DFS Replication requires two distinct servers.'; return }
if (-not $Create) { Write-Az802Status INFO ('Peer configured: {0}. Use -Create after both servers have DFS Replication installed.' -f $PeerComputerName); return }
if (-not (Get-WindowsFeature FS-DFS-Replication).Installed) { Write-Az802Status SKIP 'FS-DFS-Replication is not installed on the current server.'; return }
if (-not (Test-Az802TcpPort -ComputerName $PeerComputerName -Port 5985)) { Write-Az802Status SKIP ('WinRM is not reachable on {0}.' -f $PeerComputerName); return }
if (-not (Get-Az802DomainContext).PartOfDomain) { Write-Az802Status SKIP 'DFS Replication group management requires an Active Directory domain.'; return }

# Step 2: Verify the peer and prepare the same course content path on both members.
Write-Az802Step 2 'Prepare both replication members'
$ContentPath = 'C:\AZ802\DFS\Public'
Initialize-Az802Directory -Path $ContentPath
$RemoteArgs = @{ComputerName=$PeerComputerName;ErrorAction='Stop';ScriptBlock={
    if (-not (Get-WindowsFeature FS-DFS-Replication).Installed) { throw 'FS-DFS-Replication is not installed on the peer.' }
    New-Item -ItemType Directory -Path 'C:\AZ802\DFS\Public' -Force | Out-Null
}}
if ($PeerCredential) { $RemoteArgs.Credential = $PeerCredential }
try { Invoke-Command @RemoteArgs } catch { Write-Az802Status SKIP ('Peer preparation failed: {0}' -f $_.Exception.Message); return }
$Members = @($env:COMPUTERNAME,$PeerComputerName)

# Step 3: Create the DFSR objects only when their current state is compatible.
Write-Az802Step 3 'Create or verify the DFS Replication group'
Import-Module DFSR
$GroupName = 'AZ802-RG-Public'
$FolderName = 'AZ802-Public'
$Group = Get-DfsReplicationGroup -GroupName $GroupName -ErrorAction SilentlyContinue
if (-not $Group -and $PSCmdlet.ShouldProcess($GroupName,'Create DFS Replication group')) { New-DfsReplicationGroup -GroupName $GroupName | Out-Null }
$Group = Get-DfsReplicationGroup -GroupName $GroupName -ErrorAction SilentlyContinue
if (-not $Group) { Write-Az802Status INFO 'Replication-group creation was not performed.'; return }
foreach ($Member in $Members) {
    if (-not (Get-DfsrMember -GroupName $GroupName -ComputerName $Member -ErrorAction SilentlyContinue) -and $PSCmdlet.ShouldProcess($Member,'Add DFSR member')) { Add-DfsrMember -GroupName $GroupName -ComputerName $Member | Out-Null }
}
if (-not (Get-DfsReplicatedFolder -GroupName $GroupName -FolderName $FolderName -ErrorAction SilentlyContinue) -and $PSCmdlet.ShouldProcess($FolderName,'Create replicated folder')) { New-DfsReplicatedFolder -GroupName $GroupName -FolderName $FolderName | Out-Null }
$Connection = Get-DfsrConnection -GroupName $GroupName -SourceComputerName $env:COMPUTERNAME -DestinationComputerName $PeerComputerName -ErrorAction SilentlyContinue
if (-not $Connection -and $PSCmdlet.ShouldProcess($PeerComputerName,'Create DFSR connection')) { Add-DfsrConnection -GroupName $GroupName -SourceComputerName $env:COMPUTERNAME -DestinationComputerName $PeerComputerName | Out-Null }
foreach ($Member in $Members) {
    $Membership = Get-DfsrMembership -GroupName $GroupName -FolderName $FolderName -ComputerName $Member -ErrorAction SilentlyContinue
    if ($Membership -and $Membership.ContentPath -ine $ContentPath) { throw ('Existing DFSR membership for {0} uses {1}; expected {2}.' -f $Member,$Membership.ContentPath,$ContentPath) }
    if (-not $Membership -and $PSCmdlet.ShouldProcess($Member,'Configure DFSR membership')) {
        Set-DfsrMembership -GroupName $GroupName -FolderName $FolderName -ComputerName $Member -ContentPath $ContentPath -PrimaryMember:($Member -eq $env:COMPUTERNAME) -Force | Out-Null
    }
}
Get-DfsReplicationGroup -GroupName $GroupName
Get-DfsrMember -GroupName $GroupName
