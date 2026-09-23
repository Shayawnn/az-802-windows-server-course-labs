#Requires -Version 5.1
<#
.SYNOPSIS
Module 3 | Azure VM reference checks

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only reference checks. No Azure resource is created or changed.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 3 | Azure VM reference checks'
# Step 1: Explain the local-only boundary clearly.
Write-Az802Step 1 'Check for Azure PowerShell'
if (-not (Get-Module -ListAvailable Az.Accounts)) {
    Write-Az802Status SKIP 'Az PowerShell is not installed. Azure VM commands are optional reference material and require an authenticated Azure context.'
    return
}

# Step 2: Show the current Azure context without creating resources.
Write-Az802Step 2 'Read the current Azure context'
Import-Module Az.Accounts
$Context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $Context) { Write-Az802Status SKIP 'No Azure context is signed in. Run Connect-AzAccount deliberately when you want to use Azure.'; return }
$Context | Select-Object Account,Subscription,Tenant,Environment
