#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 2 | AD object operations

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspects course objects. Optional operations are restricted to AZ802-prefixed identities.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$UserName,
    [ValidateSet('None','Disable','Enable','Unlock','ResetPassword')][string]$UserAction = 'None',
    [Security.SecureString]$NewPassword,
    [switch]$CreateUnixUser,
    [string]$RemoveCourseObject
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | AD object operations'
if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'Active Directory PowerShell tools are not available on this machine.'; return }
Import-Module ActiveDirectory
$Domain = Get-ADDomain -ErrorAction SilentlyContinue
if (-not $Domain) { Write-Az802Status SKIP 'This lab requires an Active Directory domain.'; return }
$BaseDN = $Domain.DistinguishedName
$UsersOu = 'OU=AZ802-LabUsers,{0}' -f $BaseDN

# Step 1: Inspect the course objects before changing anything.
Write-Az802Step 1 'Inspect course-scoped AD objects'
Get-ADUser -Filter 'SamAccountName -like "AZ802-*"' -Properties Enabled,LockedOut | Select-Object SamAccountName,Enabled,LockedOut,DistinguishedName
Get-ADGroup -Filter 'SamAccountName -like "AZ802-*"' | Select-Object Name,GroupScope,DistinguishedName

# Step 2: Demonstrate account operations only against an AZ802-prefixed account.
Write-Az802Step 2 'Optional account state operation'
if ($UserName) {
    if (-not (Test-Az802CourseName $UserName)) { throw 'UserName must be AZ802-prefixed.' }
    $User = Get-ADUser -Identity $UserName -Properties LockedOut -ErrorAction Stop
    switch ($UserAction) {
        'Disable' { if ($PSCmdlet.ShouldProcess($UserName,'Disable account')) { Disable-ADAccount -Identity $UserName } }
        'Enable'  { if ($PSCmdlet.ShouldProcess($UserName,'Enable account'))  { Enable-ADAccount -Identity $UserName } }
        'Unlock'  { if ($PSCmdlet.ShouldProcess($UserName,'Unlock account'))  { Unlock-ADAccount -Identity $UserName } }
        'ResetPassword' {
            if ($PSCmdlet.ShouldProcess($UserName,'Reset password')) {
                if (-not $NewPassword) { $NewPassword = Read-Host ('New password for {0}' -f $UserName) -AsSecureString }
                Set-ADAccountPassword -Identity $UserName -NewPassword $NewPassword -Reset
                Set-ADUser -Identity $UserName -ChangePasswordAtLogon $true
            }
        }
        default { Write-Az802Status INFO 'No user action requested.' }
    }
}

# Step 3: Create an optional UNIX-attribute demonstration user without hardcoding the domain DN.
Write-Az802Step 3 'Optional UNIX-attribute user'
if ($CreateUnixUser) {
    $Sam = 'AZ802-UnixUser'
    if (-not (Get-ADUser -Identity $Sam -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($Sam,'Create UNIX-attribute lab user')) {
            if (-not $NewPassword) { $NewPassword = Read-Host ('Password for {0}' -f $Sam) -AsSecureString }
            New-ADUser -Name $Sam -SamAccountName $Sam -Path $UsersOu -AccountPassword $NewPassword -Enabled $true -ChangePasswordAtLogon $true -OtherAttributes @{uidNumber='5001';gidNumber='100';loginShell='/bin/bash';unixHomeDirectory=('/home/{0}' -f $Sam)}
        }
    }
    Get-ADUser -Identity $Sam -Properties uidNumber,gidNumber,loginShell,unixHomeDirectory | Select-Object SamAccountName,uidNumber,gidNumber,loginShell,unixHomeDirectory
}

# Step 4: Remove course objects only when explicitly requested.
Write-Az802Step 4 'Optional course-object cleanup'
if ($RemoveCourseObject) {
    if (-not (Test-Az802CourseName $RemoveCourseObject)) { throw 'Cleanup is restricted to AZ802-prefixed names.' }
    $User = Get-ADUser -Identity $RemoveCourseObject -ErrorAction SilentlyContinue
    if ($User -and $PSCmdlet.ShouldProcess($RemoveCourseObject,'Remove AD user')) { Remove-ADUser -Identity $User -Confirm:$false; return }
    $Group = Get-ADGroup -Identity $RemoveCourseObject -ErrorAction SilentlyContinue
    if ($Group -and $PSCmdlet.ShouldProcess($RemoveCourseObject,'Remove AD group')) { Remove-ADGroup -Identity $Group -Confirm:$false; return }
    $Computer = Get-ADComputer -Identity $RemoveCourseObject -ErrorAction SilentlyContinue
    if ($Computer -and $PSCmdlet.ShouldProcess($RemoveCourseObject,'Remove AD computer')) { Remove-ADComputer -Identity $Computer -Confirm:$false; return }
    Write-Az802Status SKIP 'No matching course user, group or computer was found.'
}
