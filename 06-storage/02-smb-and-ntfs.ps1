#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | SMB and NTFS

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Creates only AZ802 course share/folders. NTFS principal must be explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [switch]$CreateShare,
    [string]$NtfsPrincipal
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | SMB and NTFS'
# Step 1: Inspect or install the File Server role.
Write-Az802Step 1 'Inspect File Server and SMB state'
$Role=Get-WindowsFeature FS-FileServer
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install File Server role')) { Install-WindowsFeature FS-FileServer -IncludeManagementTools | Out-Host }
Get-SmbServerConfiguration | Select-Object EnableSMB1Protocol,EnableSMB2Protocol,RequireSecuritySignature,EncryptData

# Step 2: Create or verify a course-scoped SMB share.
Write-Az802Step 2 'Optional course SMB share'
if ($CreateShare) {
    $Path='C:\AZ802\Shares\Share01'; Initialize-Az802Directory -Path $Path
    $Existing=Get-SmbShare -Name 'AZ802-Share01' -ErrorAction SilentlyContinue
    if ($Existing -and $Existing.Path -ne $Path) { throw 'AZ802-Share01 exists with an unexpected path.' }
    $Administrators = Get-Az802AccountNameBySid -Sid 'S-1-5-32-544'
    if (-not $Existing -and $PSCmdlet.ShouldProcess('AZ802-Share01','Create SMB share')) { New-SmbShare -Name 'AZ802-Share01' -Path $Path -FullAccess $Administrators | Out-Null }
    $Existing=Get-SmbShare -Name 'AZ802-Share01' -ErrorAction SilentlyContinue
    if ($Existing) {
        if ($Existing.FolderEnumerationMode -ne 'AccessBased' -and $PSCmdlet.ShouldProcess('AZ802-Share01','Enable access-based enumeration')) { Set-SmbShare -Name 'AZ802-Share01' -FolderEnumerationMode AccessBased -Force }
        Get-SmbShare -Name 'AZ802-Share01'; Get-SmbShareAccess -Name 'AZ802-Share01'
    } else { Write-Az802Status INFO 'Share creation was not performed.' }
}

# Step 3: Add an NTFS Modify ACE only when an explicit principal is supplied.
Write-Az802Step 3 'Optional NTFS permission'
if ($NtfsPrincipal) {
    $Folder='C:\AZ802\Shares\Share01\Finance'; Initialize-Az802Directory -Path $Folder
    $Acl=Get-Acl $Folder
    $ExistingAce=$Acl.Access | Where-Object { $_.IdentityReference -eq $NtfsPrincipal -and $_.FileSystemRights.ToString().Contains('Modify') }
    if (-not $ExistingAce -and $PSCmdlet.ShouldProcess($Folder,('Grant Modify to {0}' -f $NtfsPrincipal))) {
        $Rule=New-Object System.Security.AccessControl.FileSystemAccessRule($NtfsPrincipal,'Modify','ContainerInherit,ObjectInherit','None','Allow')
        $Acl.AddAccessRule($Rule); Set-Acl -Path $Folder -AclObject $Acl
    }
    Get-Acl $Folder | Format-List
}
