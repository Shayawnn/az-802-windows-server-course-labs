#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | Failover clustering

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Missing or same-host second nodes skip. Cluster creation requires validation, explicit acknowledgement and an explicit IPv4 address.

.CHANGES
Optionally validates and creates AZ802-CLUSTER across two real Windows Server nodes.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [string]$SecondNode,
    [PSCredential]$PeerCredential,
    [switch]$Validate,
    [switch]$Create,
    [switch]$ValidationReviewed,
    [string]$StaticAddress
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | Failover clustering'
$Config = Import-Az802Config -RepoRoot $RepoRoot
if (-not $SecondNode) { $SecondNode = $Config.PeerWindowsHost }

# Step 1: Inspect or install Failover Clustering tools on the current host.
Write-Az802Step 1 'Inspect Failover Clustering state'
$Role = Get-WindowsFeature Failover-Clustering
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install Failover Clustering')) { Install-WindowsFeature Failover-Clustering -IncludeManagementTools | Out-Host }
if (-not (Get-WindowsFeature Failover-Clustering).Installed) { Write-Az802Status SKIP 'Failover Clustering is not installed on the current server.'; return }
if (-not $SecondNode) { Write-Az802Status SKIP 'No second Windows Server is configured. Cluster validation/creation requires at least two nodes.'; return }
$SecondShort = ($SecondNode -split '\.')[0]
if ($SecondNode -in @('localhost','127.0.0.1','::1','.') -or $SecondShort -ieq $env:COMPUTERNAME) { Write-Az802Status SKIP 'The second cluster node must be a different Windows Server.'; return }
if (-not (Test-Az802TcpPort -ComputerName $SecondNode -Port 5985)) { Write-Az802Status SKIP ('WinRM is not reachable on {0}; peer prerequisites cannot be verified.' -f $SecondNode); return }
$RemoteArgs = @{ComputerName=$SecondNode;ErrorAction='Stop';ScriptBlock={ (Get-WindowsFeature Failover-Clustering).Installed }}
if ($PeerCredential) { $RemoteArgs.Credential = $PeerCredential }
try { $PeerFeatureInstalled = [bool](Invoke-Command @RemoteArgs) } catch { Write-Az802Status SKIP ('Could not verify the peer cluster feature: {0}' -f $_.Exception.Message); return }
if (-not $PeerFeatureInstalled) { Write-Az802Status SKIP ('Failover Clustering is not installed on {0}.' -f $SecondNode); return }
$Nodes = @($env:COMPUTERNAME,$SecondNode)

# Step 2: Run Microsoft cluster validation before any creation attempt.
Write-Az802Step 2 'Validate the candidate nodes'
if (-not $Validate) { Write-Az802Status INFO ('Use -Validate to run Test-Cluster for {0}.' -f ($Nodes -join ', ')); return }
Test-Cluster -Node $Nodes -ErrorAction Continue | Out-Host
Write-Az802Status INFO 'Review the Test-Cluster report and warnings before creating a cluster.'
if (-not $Create) { return }
if (-not $ValidationReviewed) { throw 'Supply -ValidationReviewed only after reviewing the Test-Cluster report.' }
if (-not $StaticAddress -or -not (Test-Az802IPv4Address $StaticAddress)) { throw 'Supply an explicit valid IPv4 -StaticAddress for the course cluster.' }

# Step 3: Create the course cluster only after explicit validation acknowledgement.
Write-Az802Step 3 'Optional cluster creation'
$Existing = Get-Cluster -Name 'AZ802-CLUSTER' -ErrorAction SilentlyContinue
if ($Existing) { Write-Az802Status OK 'AZ802-CLUSTER already exists.' }
elseif ($PSCmdlet.ShouldProcess('AZ802-CLUSTER','Create failover cluster')) { New-Cluster -Name 'AZ802-CLUSTER' -Node $Nodes -StaticAddress $StaticAddress | Out-Host }
Get-Cluster -Name 'AZ802-CLUSTER' -ErrorAction SilentlyContinue
Get-ClusterNode -Cluster 'AZ802-CLUSTER' -ErrorAction SilentlyContinue
