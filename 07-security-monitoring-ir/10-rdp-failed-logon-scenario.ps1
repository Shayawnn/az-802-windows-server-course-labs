#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | RDP failed-logon scenario

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Uses an AZ802-prefixed disposable account, preserves the original RDP registry baseline, and uses a course-scoped firewall rule rather than changing built-in firewall rules.

.CHANGES
Build enables RDP/NLA and creates a disposable account appropriate to either a member/workgroup server or a domain controller. Repair removes the account and restores the saved baseline unless an explicit restricted source is requested.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Build','Observe','Repair','Verify')][string]$Phase = 'Observe',
    [Security.SecureString]$Password,
    [string]$RestrictRemoteAddress
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | RDP failed-logon scenario'
$StateDir = 'C:\AZ802\State'
$StateFile = Join-Path $StateDir 'rdp-scenario-baseline.json'
$UserName = 'AZ802-RdpDemo'
$RuleName = 'AZ802-RDP-3389'
$IsDc = Test-Az802IsDomainController

function Get-Az802RdpDemoAccount {
    if ($IsDc) {
        if (-not (Test-Az802Command Get-ADUser)) { return $null }
        return Get-ADUser -Identity $UserName -ErrorAction SilentlyContinue
    }
    return Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
}

# Step 1: Execute the selected RDP scenario phase.
Write-Az802Step 1 ('Scenario phase: {0}' -f $Phase)
switch ($Phase) {
    'Build' {
        if (-not (Test-Path -LiteralPath $StateDir) -and $PSCmdlet.ShouldProcess($StateDir,'Create the scenario state directory')) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
        if (-not (Test-Path -LiteralPath $StateFile)) {
            $Deny = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
            $Nla = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').UserAuthentication
            if ($PSCmdlet.ShouldProcess($StateFile,'Save the pre-lab RDP baseline')) {
                @{fDenyTSConnections=[int]$Deny;UserAuthentication=[int]$Nla;Created=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath $StateFile
            }
        }
        if ($PSCmdlet.ShouldProcess('RDP configuration','Enable RDP and require Network Level Authentication for the lab')) {
            Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' fDenyTSConnections 0
            Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' UserAuthentication 1
        }

        $Rule = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
        if ($Rule) {
            $PortFilter = $Rule | Get-NetFirewallPortFilter
            if ($PortFilter.Protocol -ne 'TCP' -or [string]$PortFilter.LocalPort -ne '3389') { throw ('Firewall rule {0} exists with an unexpected protocol or port.' -f $RuleName) }
            if ($Rule.Enabled -ne 'True' -and $PSCmdlet.ShouldProcess($RuleName,'Enable course RDP firewall rule')) { Enable-NetFirewallRule -Name $RuleName }
        } elseif ($PSCmdlet.ShouldProcess($RuleName,'Create course RDP firewall rule')) {
            New-NetFirewallRule -Name $RuleName -DisplayName 'AZ802 | RDP lab TCP 3389' -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow | Out-Null
        }

        if ($IsDc) {
            if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'This server is a domain controller, but Active Directory PowerShell tools are not available.'; return }
            Import-Module ActiveDirectory
            $Domain = Get-ADDomain
            $UsersOu = 'OU=AZ802-LabUsers,{0}' -f $Domain.DistinguishedName
            $Path = if (Get-ADOrganizationalUnit -Identity $UsersOu -ErrorAction SilentlyContinue) { $UsersOu } else { $Domain.UsersContainer }
            if (-not (Get-ADUser -Identity $UserName -ErrorAction SilentlyContinue) -and $PSCmdlet.ShouldProcess($UserName,'Create disposable domain RDP account')) {
                if (-not $Password) { $Password = Read-Host ('Password for {0}' -f $UserName) -AsSecureString }
                New-ADUser -Name $UserName -SamAccountName $UserName -Path $Path -AccountPassword $Password -Enabled $true -ChangePasswordAtLogon $false -Description 'AZ-802 disposable RDP lab account'
            }
            $User = Get-ADUser -Identity $UserName -ErrorAction SilentlyContinue
            if ($User) {
                $RdpUsers = Get-ADGroup -Identity 'S-1-5-32-555' -ErrorAction Stop
                if (-not (Get-ADGroupMember -Identity $RdpUsers | Where-Object SamAccountName -eq $UserName) -and $PSCmdlet.ShouldProcess($UserName,'Add to Remote Desktop Users')) { Add-ADGroupMember -Identity $RdpUsers -Members $User }
                $LoginName = '{0}\{1}' -f $Domain.NetBIOSName,$UserName
            }
        } else {
            if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) -and $PSCmdlet.ShouldProcess($UserName,'Create disposable local RDP account')) {
                if (-not $Password) { $Password = Read-Host ('Password for {0}' -f $UserName) -AsSecureString }
                New-LocalUser -Name $UserName -FullName 'AZ802 RDP Demo' -Password $Password | Out-Null
            }
            $User = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
            if ($User) {
                $RdpUsers = Get-Az802LocalGroupNameBySid -Sid 'S-1-5-32-555'
                if (-not (Get-LocalGroupMember $RdpUsers | Where-Object Name -Match ('\\{0}$' -f [regex]::Escape($UserName))) -and $PSCmdlet.ShouldProcess($UserName,'Add to Remote Desktop Users')) { Add-LocalGroupMember -Group $RdpUsers -Member $UserName }
                $LoginName = '{0}\{1}' -f $env:COMPUTERNAME,$UserName
            }
        }
        if ($User) { Write-Az802Status INFO ('From a separate Windows client, attempt RDP as {0} and intentionally enter an incorrect password two or three times.' -f $LoginName) }
        else { Write-Az802Status INFO 'Account creation was not performed.' }
    }
    'Observe' {
        Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625;StartTime=(Get-Date).AddHours(-2)} -MaxEvents 50 -ErrorAction SilentlyContinue | Where-Object Message -Match 'Logon Type:\s+10' | Select-Object TimeCreated,Id,Message
    }
    'Repair' {
        if ($IsDc) {
            if (Test-Az802Command Get-ADUser) {
                Import-Module ActiveDirectory
                $User = Get-ADUser -Identity $UserName -ErrorAction SilentlyContinue
                if ($User -and $PSCmdlet.ShouldProcess($UserName,'Remove disposable domain RDP account')) { Remove-ADUser -Identity $User -Confirm:$false }
            }
        } else {
            if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) { if ($PSCmdlet.ShouldProcess($UserName,'Remove disposable local RDP account')) { Remove-LocalUser -Name $UserName } }
        }

        if ($RestrictRemoteAddress) {
            $Rule = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
            if (-not $Rule) { throw 'The AZ802 RDP firewall rule does not exist. Run Build first.' }
            if ($PSCmdlet.ShouldProcess($RuleName,('Restrict RDP source to {0}' -f $RestrictRemoteAddress))) {
                Enable-NetFirewallRule -Name $RuleName
                $Rule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress $RestrictRemoteAddress
                Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' fDenyTSConnections 0
                Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' UserAuthentication 1
            }
            Write-Az802Status OK ('RDP remains enabled with the course firewall rule restricted to {0}.' -f $RestrictRemoteAddress)
        } elseif (Test-Path -LiteralPath $StateFile) {
            $Baseline = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
            if ($PSCmdlet.ShouldProcess('RDP configuration','Restore the saved pre-lab RDP baseline')) {
                Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' fDenyTSConnections ([int]$Baseline.fDenyTSConnections)
                Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' UserAuthentication ([int]$Baseline.UserAuthentication)
                $Rule = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
                if ($Rule) { Remove-NetFirewallRule -Name $RuleName }
            }
        }
        if ((Test-Path -LiteralPath $StateFile) -and $PSCmdlet.ShouldProcess($StateFile,'Remove completed RDP scenario baseline')) { Remove-Item -LiteralPath $StateFile -Force }
    }
    'Verify' {
        Write-Az802Status INFO ('RDP deny flag: {0}' -f (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections)
        Write-Az802Status INFO ('NLA required: {0}' -f (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').UserAuthentication)
        Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue | Select-Object DisplayName,Enabled,Direction,Action
        if (-not (Get-Az802RdpDemoAccount)) { Write-Az802Status OK 'Disposable RDP demo account is absent.' }
        else { Write-Az802Status WARN 'Disposable RDP demo account still exists.' }
    }
}
