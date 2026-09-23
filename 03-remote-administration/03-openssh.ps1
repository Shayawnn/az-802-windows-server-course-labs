#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 3 | OpenSSH

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. OpenSSH installation/configuration and public-key changes are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$InstallServer,
    [switch]$ConfigureServer,
    [string]$TargetUser,
    [string]$PublicKey
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 3 | OpenSSH'
# Step 1: Inspect OpenSSH capabilities and service state.
Write-Az802Step 1 'Inspect OpenSSH state'
$Capabilities = Get-WindowsCapability -Online | Where-Object Name -Like 'OpenSSH*'
$Capabilities | Select-Object Name,State
Get-Service sshd -ErrorAction SilentlyContinue

# Step 2: Install OpenSSH Server only when requested.
Write-Az802Step 2 'Optional OpenSSH Server installation'
if ($InstallServer) {
    $ServerCap = $Capabilities | Where-Object Name -Like 'OpenSSH.Server*' | Select-Object -First 1
    if (-not $ServerCap) { throw 'OpenSSH Server capability was not found on this Windows image.' }
    if ($ServerCap.State -ne 'Installed' -and $PSCmdlet.ShouldProcess($ServerCap.Name,'Install Windows capability')) { Add-WindowsCapability -Online -Name $ServerCap.Name | Out-Host }
}

# Step 3: Configure sshd only when requested.
Write-Az802Step 3 'Optional sshd service and course firewall rule'
if ($ConfigureServer) {
    if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) { throw 'OpenSSH Server is not installed.' }
    if ($PSCmdlet.ShouldProcess('sshd','Start service and set Automatic')) { Set-Service sshd -StartupType Automatic; Start-Service sshd }
    $RuleName = 'AZ802-OpenSSH-22'
    if (-not (Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue) -and $PSCmdlet.ShouldProcess($RuleName,'Create TCP/22 firewall rule')) {
        New-NetFirewallRule -Name $RuleName -DisplayName 'AZ802 | OpenSSH Server' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow | Out-Null
    }
}

# Step 4: Add a public key safely when supplied.
Write-Az802Step 4 'Optional key-based authentication setup'
if ($PublicKey) {
    if (-not $TargetUser) { throw 'Supply -TargetUser with -PublicKey.' }
    if (Test-Az802IsDomainController) { Write-Az802Status SKIP 'This public-key example targets a local account on a member/workgroup server. A domain controller has no local SAM; use a member server or configure the domain account deliberately.'; return }
    $User = Get-LocalUser -Name $TargetUser -ErrorAction SilentlyContinue
    if (-not $User) { throw ('Local user not found: {0}' -f $TargetUser) }
    $Admins = Get-Az802LocalGroupNameBySid -Sid 'S-1-5-32-544'
    $IsAdmin = [bool](Get-LocalGroupMember -Group $Admins | Where-Object Name -Match ('\\{0}$' -f [regex]::Escape($TargetUser)))
    if ($IsAdmin) {
        $KeyFile = 'C:\ProgramData\ssh\administrators_authorized_keys'
        Initialize-Az802Directory -Path 'C:\ProgramData\ssh'
    } else {
        $Profile = (Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -match ('\\{0}$' -f [regex]::Escape($TargetUser)) } | Select-Object -First 1).LocalPath
        if (-not $Profile) { throw 'Target user profile does not exist yet. Sign in once or create the profile first.' }
        Initialize-Az802Directory -Path (Join-Path $Profile '.ssh')
        $KeyFile = Join-Path $Profile '.ssh\authorized_keys'
    }
    $ExistingKeys = @(); if (Test-Path $KeyFile) { $ExistingKeys = Get-Content $KeyFile }
    if ($ExistingKeys -notcontains $PublicKey -and $PSCmdlet.ShouldProcess($KeyFile,'Append SSH public key')) { Add-Content -Path $KeyFile -Value $PublicKey }
    if ($IsAdmin -and (Test-Path -LiteralPath $KeyFile) -and $PSCmdlet.ShouldProcess($KeyFile,'Apply administrator authorized_keys ACL')) {
        & icacls.exe $KeyFile /inheritance:r | Out-Null
        & icacls.exe $KeyFile /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' | Out-Null
    }
    Write-Az802Status OK ('Authorized-key file: {0}' -f $KeyFile)
}
