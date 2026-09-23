#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 2 | Domain baseline

.RUN ON
A domain controller or domain-joined administration server with the Active Directory module.

.SAFE TO RERUN
Yes

.CHANGES
Inspects the course AD baseline by default. -CreateBaseline creates AZ802-scoped OUs, ordinary users and the security group. Course administrator creation and Domain Admin membership are separately opt-in.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$CreateBaseline,
    [switch]$CreateCourseAdmin,
    [Security.SecureString]$CourseAdminPassword,
    [switch]$AddCourseAdminToDomainAdmins,
    [Security.SecureString]$CourseUserPassword
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | Domain baseline'

$Context = Get-Az802DomainContext
if (-not $Context.PartOfDomain) { Write-Az802Status SKIP 'The current server is not domain joined. Create/join a domain before building the AD baseline.'; return }
if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'The Active Directory PowerShell module is not available. Install AD DS/RSAT management tools first.'; return }
Import-Module ActiveDirectory
$Domain = Get-ADDomain -ErrorAction Stop
$BaseDN = $Domain.DistinguishedName

# Step 1: Verify the current domain and directory services.
Write-Az802Step 1 'Verify domain state'
$Domain | Select-Object DNSRoot,NetBIOSName,DistinguishedName,DomainMode,PDCEmulator
Get-ADDomainController -Discover | Select-Object HostName,Site,IPv4Address

# Step 2: Inspect the course OUs; create them only when baseline/admin creation is requested.
Write-Az802Step 2 'Inspect or create course organizational units'
$CreateCourseOus = $CreateBaseline -or $CreateCourseAdmin
foreach ($Name in @('AZ802-LabUsers','AZ802-Groups','AZ802-Servers','AZ802-Workstations')) {
    $Dn = 'OU={0},{1}' -f $Name,$BaseDN
    # $Existing = Get-ADOrganizationalUnit -Identity $Dn -ErrorAction SilentlyContinue
    $Existing = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$Dn'" -ErrorAction SilentlyContinue
    if ($Existing) {
        Write-Az802Status OK ('OU exists: {0}' -f $Dn)
    } elseif ($CreateCourseOus -and $PSCmdlet.ShouldProcess($Dn,'Create OU')) {
        New-ADOrganizationalUnit -Name $Name -Path $BaseDN -ProtectedFromAccidentalDeletion $true
        Write-Az802Status CREATE ('Created OU {0}' -f $Dn)
    } else {
        Write-Az802Status INFO ('OU is absent: {0}. Use -CreateBaseline to build the course baseline.' -f $Dn)
    }
}

# Step 3: Create the course administrator only when requested.
Write-Az802Step 3 'Optional course domain administrator'
$AdminSam = 'AZ802-Admin'
# $Admin = Get-ADUser -Identity $AdminSam -ErrorAction SilentlyContinue
$Admin = Get-ADUser -Filter "SamAccountName -eq '$AdminSam'" -ErrorAction SilentlyContinue
if ($CreateCourseAdmin -and -not $Admin) {
    if ($PSCmdlet.ShouldProcess($AdminSam,'Create course domain user')) {
        if (-not $CourseAdminPassword) { $CourseAdminPassword = Read-Host ('Password for {0}' -f $AdminSam) -AsSecureString }
        New-ADUser -Name 'AZ802 Course Admin' -SamAccountName $AdminSam -UserPrincipalName ('{0}@{1}' -f $AdminSam,$Domain.DNSRoot) -AccountPassword $CourseAdminPassword -Enabled $true -ChangePasswordAtLogon $true -Path ('OU=AZ802-LabUsers,{0}' -f $BaseDN)
        Write-Az802Status CREATE ('Created {0}.' -f $AdminSam)
    }
} elseif ($Admin) {
    Write-Az802Status OK ('Course administrator exists: {0}.' -f $AdminSam)
} elseif (-not $CreateCourseAdmin) {
    Write-Az802Status INFO 'Use -CreateCourseAdmin when you want a disposable course administrator account.'
}

if ($AddCourseAdminToDomainAdmins) {
    $Admin = Get-ADUser -Filter "SamAccountName -eq '$AdminSam'" -ErrorAction SilentlyContinue
    if (-not $Admin) { throw 'Create AZ802-Admin first with -CreateCourseAdmin.' }
    $DomainAdminsSid = '{0}-512' -f $Domain.DomainSID.Value
    # $DomainAdmins = Get-ADGroup -Identity $DomainAdminsSid -ErrorAction Stop
    $DomainAdmins = Get-ADGroup -Filter "SID -eq '$DomainAdminsSid'" -ErrorAction Stop
    $Member = Get-ADGroupMember -Identity $DomainAdmins -Recursive | Where-Object SamAccountName -eq $AdminSam
    if ($Member) {
        Write-Az802Status OK ('{0} is already a member of {1}.' -f $AdminSam,$DomainAdmins.Name)
    } elseif ($PSCmdlet.ShouldProcess($AdminSam,('Add to {0}' -f $DomainAdmins.Name))) {
        Add-ADGroupMember -Identity $DomainAdmins -Members $Admin
        Write-Az802Status CHANGE ('Added {0} to {1}.' -f $AdminSam,$DomainAdmins.Name)
    }
}

# Step 4: Inspect ordinary course users and the course security group; create them only with -CreateBaseline.
Write-Az802Step 4 'Inspect or create course users and security group'
$UsersOu = 'OU=AZ802-LabUsers,{0}' -f $BaseDN
foreach ($Sam in @('AZ802-User01','AZ802-User02')) {
    # $ExistingUser = Get-ADUser -Identity $Sam -ErrorAction SilentlyContinue
    $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$Sam'" -ErrorAction SilentlyContinue
    if ($ExistingUser) {
        Write-Az802Status OK ('Course user exists: {0}.' -f $Sam)
    } elseif ($CreateBaseline) {
        # if (-not (Get-ADOrganizationalUnit -Identity $UsersOu -ErrorAction SilentlyContinue)) { throw 'AZ802-LabUsers OU is missing. Rerun with -CreateBaseline after resolving the OU creation error.' }
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$UsersOu'" -ErrorAction SilentlyContinue)) { throw 'AZ802-LabUsers OU is missing. Rerun with -CreateBaseline after resolving the OU creation error.' }
        if ($PSCmdlet.ShouldProcess($Sam,'Create course domain user')) {
            if (-not $CourseUserPassword) { $CourseUserPassword = Read-Host 'Password for course users' -AsSecureString }
            New-ADUser -Name $Sam -SamAccountName $Sam -UserPrincipalName ('{0}@{1}' -f $Sam,$Domain.DNSRoot) -AccountPassword $CourseUserPassword -Enabled $true -ChangePasswordAtLogon $true -Path $UsersOu
            Write-Az802Status CREATE ('Created {0}.' -f $Sam)
        }
    } else {
        Write-Az802Status INFO ('Course user is absent: {0}. Use -CreateBaseline to create the ordinary course users.' -f $Sam)
    }
}

$GroupDn = 'CN=AZ802-Development,OU=AZ802-Groups,{0}' -f $BaseDN
# $ExistingGroup = Get-ADGroup -Identity $GroupDn -ErrorAction SilentlyContinue
$ExistingGroup = Get-ADGroup -Filter "DistinguishedName -eq '$GroupDn'" -ErrorAction SilentlyContinue
if ($ExistingGroup) {
    Write-Az802Status OK 'Course group exists: AZ802-Development.'
} elseif ($CreateBaseline) {
    $GroupsOu = 'OU=AZ802-Groups,{0}' -f $BaseDN
    # if (-not (Get-ADOrganizationalUnit -Identity $GroupsOu -ErrorAction SilentlyContinue)) { throw 'AZ802-Groups OU is missing. Rerun with -CreateBaseline after resolving the OU creation error.' }
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$GroupsOu'" -ErrorAction SilentlyContinue)) { throw 'AZ802-Groups OU is missing. Rerun with -CreateBaseline after resolving the OU creation error.' }
    if ($PSCmdlet.ShouldProcess('AZ802-Development','Create course security group')) {
        New-ADGroup -Name 'AZ802-Development' -SamAccountName 'AZ802-Development' -GroupScope Global -GroupCategory Security -Path $GroupsOu -Description 'AZ-802 course lab group'
        Write-Az802Status CREATE 'Created AZ802-Development.'
    }
} else {
    Write-Az802Status INFO 'Course group is absent: AZ802-Development. Use -CreateBaseline to create it.'
}
Get-ADUser -Filter 'SamAccountName -like "AZ802-*"' | Select-Object Name,SamAccountName,Enabled
# Get-ADGroup -Identity 'AZ802-Development' -ErrorAction SilentlyContinue
Get-ADGroup -Filter 'SamAccountName -eq "AZ802-Development"' | Select-Object Name,SamAccountName,GroupScope,GroupCategory
