#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Protected Users and VBS

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
VBS inspection by default. Protected Users membership is restricted to an explicit AZ802-prefixed AD user.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$UserName,
    [switch]$OpenMsInfo
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Protected Users and VBS'
# Step 1: Inspect virtualization-based security state.
Write-Az802Step 1 'Inspect virtualization-based security state'
Get-ComputerInfo | Select-Object DeviceGuardSecurityServicesConfigured,DeviceGuardSecurityServicesRunning,DeviceGuardVirtualizationBasedSecurityStatus
if ($OpenMsInfo -and (Test-Path "$env:WINDIR\System32\msinfo32.exe")) { Start-Process msinfo32.exe }

# Step 2: Add only an explicit AZ802 domain user to Protected Users.
Write-Az802Step 2 'Optional Protected Users membership'
if ($UserName) {
    if (-not (Test-Az802CourseName $UserName)) { throw 'UserName must be AZ802-prefixed for this course script.' }
    if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'Active Directory PowerShell tools are not available.'; return }
    Import-Module ActiveDirectory
    $Domain = Get-ADDomain -ErrorAction SilentlyContinue
    if (-not $Domain) { Write-Az802Status SKIP 'Protected Users membership requires an Active Directory domain.'; return }
    $User=Get-ADUser -Identity $UserName -ErrorAction Stop
    $ProtectedUsersSid = '{0}-525' -f $Domain.DomainSID.Value
    $Group=Get-ADGroup -Identity $ProtectedUsersSid -ErrorAction SilentlyContinue
    if (-not $Group) { throw ('Protected Users group was not found at SID {0}.' -f $ProtectedUsersSid) }
    if (-not (Get-ADGroupMember $Group -Recursive | Where-Object SamAccountName -eq $UserName) -and $PSCmdlet.ShouldProcess($UserName,'Add to Protected Users')) { Add-ADGroupMember -Identity $Group -Members $User }
    Get-ADGroupMember $Group
}
