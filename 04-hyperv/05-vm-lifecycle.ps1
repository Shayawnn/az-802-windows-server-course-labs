#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | VM lifecycle

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspects VM lifecycle state by default. Checkpoint and export actions are explicit and guarded.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VMName = 'AZ802-WIN01',
    [string]$CheckpointName = 'AZ802-BeforeChange',
    [switch]$CreateCheckpoint,
    [switch]$RestoreCheckpoint,
    [switch]$RemoveCheckpoint,
    [string]$ExportPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | VM lifecycle'
if (-not (Get-VM -Name $VMName -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP ('VM not found: {0}' -f $VMName); return }

# Step 1: Inspect checkpoints and VM state.
Write-Az802Step 1 'Inspect VM and checkpoints'
Get-VM -Name $VMName | Select-Object Name,State,CheckpointType,Uptime
Get-VMSnapshot -VMName $VMName -ErrorAction SilentlyContinue | Select-Object VMName,Name,CreationTime,SnapshotType

# Step 2: Create a checkpoint only when requested and absent.
Write-Az802Step 2 'Optional checkpoint creation'
if ($CreateCheckpoint) {
    if (Get-VMSnapshot -VMName $VMName -Name $CheckpointName -ErrorAction SilentlyContinue) { Write-Az802Status OK 'Checkpoint already exists.' }
    elseif ($PSCmdlet.ShouldProcess($VMName,('Create checkpoint {0}' -f $CheckpointName))) { Checkpoint-VM -Name $VMName -SnapshotName $CheckpointName | Out-Null }
}

# Step 3: Restore or remove an existing checkpoint only with explicit switches.
Write-Az802Step 3 'Optional checkpoint restore or removal'
$Snapshot = Get-VMSnapshot -VMName $VMName -Name $CheckpointName -ErrorAction SilentlyContinue
if ($RestoreCheckpoint) {
    if (-not $Snapshot) { Write-Az802Status SKIP 'Requested checkpoint does not exist.' }
    elseif ($PSCmdlet.ShouldProcess($CheckpointName,'Restore checkpoint')) { Restore-VMSnapshot -VMName $VMName -Name $CheckpointName -Confirm:$false }
}
if ($RemoveCheckpoint) {
    $Snapshot = Get-VMSnapshot -VMName $VMName -Name $CheckpointName -ErrorAction SilentlyContinue
    if (-not $Snapshot) { Write-Az802Status SKIP 'Requested checkpoint is already absent.' }
    elseif ($PSCmdlet.ShouldProcess($CheckpointName,'Remove checkpoint')) { Remove-VMSnapshot -VMName $VMName -Name $CheckpointName -Confirm:$false }
}

# Step 4: Export only to an explicit directory and do not overwrite an existing export silently.
Write-Az802Step 4 'Optional VM export'
if ($ExportPath) {
    Initialize-Az802Directory -Path $ExportPath
    $Existing = Join-Path $ExportPath $VMName
    if (Test-Path -LiteralPath $Existing) { Write-Az802Status SKIP ('Export destination already exists: {0}' -f $Existing) }
    else {
        if ((Get-VM -Name $VMName).State -ne 'Off') { Write-Az802Status SKIP 'Stop the VM before export for a predictable classroom workflow.' }
        elseif ($PSCmdlet.ShouldProcess($VMName,('Export to {0}' -f $ExportPath))) { Export-VM -Name $VMName -Path $ExportPath }
    }
}
