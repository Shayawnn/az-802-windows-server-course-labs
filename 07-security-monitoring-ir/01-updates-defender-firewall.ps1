#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Updates, Defender and Firewall

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspection by default. Defender signature update and quick scan are opt-in.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$UpdateSignatures,
    [switch]$QuickScan
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Updates, Defender and Firewall'
# Step 1: Read update and reboot state.
Write-Az802Step 1 'Inspect update and reboot state'
Get-ComputerInfo | Select-Object OsName,OsVersion,WindowsVersion,CsName
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10
[pscustomobject]@{
    WindowsUpdateRebootRequired = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    PendingFileRenameOperations = Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations'
}

# Step 2: Read Defender state when Defender cmdlets are available.
Write-Az802Step 2 'Inspect Microsoft Defender state'
if (Test-Az802Command Get-MpComputerStatus) {
    Get-MpComputerStatus | Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,NISEnabled,AntivirusSignatureLastUpdated
    Get-MpThreatDetection -ErrorAction SilentlyContinue
    if ($UpdateSignatures) { Update-MpSignature }
    if ($QuickScan) { Start-MpScan -ScanType QuickScan }
} else { Write-Az802Status SKIP 'Microsoft Defender cmdlets are not available on this installation.' }

# Step 3: Inspect firewall profiles and active inbound rules.
Write-Az802Step 3 'Inspect Windows Defender Firewall'
Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction
Get-NetFirewallRule -Enabled True -Direction Inbound | Select-Object -First 30 DisplayName,Profile,Action
