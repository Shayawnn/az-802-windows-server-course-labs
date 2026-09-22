#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 1 | Local accounts

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Creates or verifies an AZ802-prefixed local user. Administrator membership and cleanup are opt-in.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$UserName = 'AZ802-LocalAdmin',
    [Security.SecureString]$Password,
    [switch]$AddToAdministrators,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 1 | Local accounts'
if (Test-Az802IsDomainController) { Write-Az802Status SKIP 'Local-user lab is not applicable on a domain controller.'; return }
$Administrators = Get-Az802LocalGroupNameBySid -Sid 'S-1-5-32-544'

# Step 1: Create or verify the course-scoped local account.
Write-Az802Step 1 'Create or verify the local lab account'
$Existing = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
if (-not $Existing) {
    if ($PSCmdlet.ShouldProcess($UserName,'Create local user')) {
        if (-not $Password) { $Password = Read-Host ('Password for {0}' -f $UserName) -AsSecureString }
        New-LocalUser -Name $UserName -FullName 'AZ-802 Lab Administrator' -Description 'Disposable AZ-802 local lab account' -Password $Password | Out-Null
        Write-Az802Status CREATE ('Created local user {0}' -f $UserName)
    }
} else { Write-Az802Status OK ('Local user exists: {0}' -f $UserName) }

# Step 2: Add the user to the built-in Administrators group when requested.
Write-Az802Step 2 'Manage local administrator membership'
if ($AddToAdministrators) {
    $Member = Get-LocalGroupMember -Group $Administrators -ErrorAction Stop | Where-Object Name -Match ('\\{0}$' -f [regex]::Escape($UserName))
    if (-not $Member -and $PSCmdlet.ShouldProcess($UserName,'Add to local Administrators')) { Add-LocalGroupMember -Group $Administrators -Member $UserName }
    Get-LocalGroupMember -Group $Administrators | Select-Object Name,ObjectClass,PrincipalSource
} else { Write-Az802Status INFO 'Use -AddToAdministrators to demonstrate privileged group membership.' }

# Step 3: Remove only the course account when cleanup is explicitly requested.
Write-Az802Step 3 'Optional cleanup'
if ($Remove) {
    if (-not (Test-Az802CourseName $UserName)) { throw 'Cleanup is restricted to AZ802-prefixed accounts.' }
    if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($UserName,'Remove local user')) { Remove-LocalUser -Name $UserName; Write-Az802Status OK 'Course account removed.' }
    } else { Write-Az802Status OK 'Course account is already absent.' }
} else { Write-Az802Status INFO 'Use -Remove when you deliberately want to remove the course-created account.' }
