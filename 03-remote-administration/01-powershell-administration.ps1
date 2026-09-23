#Requires -Version 5.1
<#
.SYNOPSIS
Module 3 | PowerShell administration

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Reads server state and writes a small course report under C:\AZ802\Reports.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 3 | PowerShell administration'
# Step 1: Inventory installed roles and basic server state.
Write-Az802Step 1 'Read installed roles and server state'
Get-WindowsFeature | Where-Object Installed | Select-Object DisplayName,Name,InstallState
Get-ComputerInfo | Select-Object CsName,WindowsProductName,WindowsVersion
Get-NetIPConfiguration
Get-Volume

# Step 2: Query recent system events.
Write-Az802Step 2 'Read recent System events'
Get-WinEvent -LogName System -MaxEvents 20 | Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message

# Step 3: Create a small administration report under the course root.
Write-Az802Step 3 'Create a server report'
$ReportPath = 'C:\AZ802\Reports\ServerReport'
Initialize-Az802Directory -Path $ReportPath
Get-ComputerInfo | Out-File (Join-Path $ReportPath 'computer.txt')
Get-Service | Sort-Object Status,Name | Out-File (Join-Path $ReportPath 'services.txt')
Get-NetIPConfiguration | Out-File (Join-Path $ReportPath 'network.txt')
Write-Az802Status OK ('Report written to {0}' -f $ReportPath)
