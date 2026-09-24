#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | RDP and RDS advanced operations

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Principal membership and RDS-role installation are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Principal,
    [switch]$InstallRds
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | RDP and RDS advanced operations'
# Step 1: Add an explicit principal to Remote Desktop Users only when requested.
Write-Az802Step 1 'Optional Remote Desktop Users membership'
if ($Principal) {
    $Group=Get-Az802LocalGroupNameBySid -Sid 'S-1-5-32-555'
    $Existing=Get-LocalGroupMember -Group $Group -ErrorAction Stop | Where-Object Name -eq $Principal
    if (-not $Existing -and $PSCmdlet.ShouldProcess($Principal,('Add to {0}' -f $Group))) { Add-LocalGroupMember -Group $Group -Member $Principal }
    Get-LocalGroupMember -Group $Group
}

# Step 2: Install RDS roles only when explicitly requested.
Write-Az802Step 2 'Optional RDS role installation'
if ($InstallRds) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install RDS role services')) { Install-WindowsFeature Remote-Desktop-Services,RDS-Web-Access,RDS-RD-Server,RDS-Connection-Broker,RDS-Licensing -IncludeManagementTools | Out-Host }
    Write-Az802Status WARN 'RDS deployment design, licensing and restart requirements extend beyond simply installing role binaries.'
}
