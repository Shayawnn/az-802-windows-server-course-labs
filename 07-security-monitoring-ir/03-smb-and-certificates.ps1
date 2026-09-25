#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | SMB security and certificates

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
SMB changes and certificate creation are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$DisableSmb1,
    [string]$ShareName,
    [switch]$EnableShareEncryption,
    [string]$DnsName,
    [switch]$CreateCertificate
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | SMB security and certificates'
# Step 1: Inspect SMB security posture.
Write-Az802Step 1 'Inspect SMB server security'
Get-SmbServerConfiguration | Select-Object EnableSMB1Protocol,EnableSMB2Protocol,RejectUnencryptedAccess,EncryptData,RequireSecuritySignature
if ($DisableSmb1 -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Disable SMB1 server protocol')) { Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force }

# Step 2: Enable encryption only on an explicit existing share.
Write-Az802Step 2 'Optional SMB share encryption'
if ($ShareName) {
    $Share=Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
    if (-not $Share) { Write-Az802Status SKIP ('Share not found: {0}' -f $ShareName) }
    elseif ($EnableShareEncryption -and -not $Share.EncryptData -and $PSCmdlet.ShouldProcess($ShareName,'Enable SMB encryption')) { Set-SmbShare -Name $ShareName -EncryptData $true -Force }
    Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue | Select-Object Name,Path,EncryptData
}

# Step 3: Create a course self-signed certificate only with an explicit DNS name.
Write-Az802Step 3 'Optional self-signed lab certificate'
if ($DnsName -and $CreateCertificate) {
    $Friendly='AZ802 Lab TLS'
    $Existing=Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $Friendly -and $_.Subject -match [regex]::Escape($DnsName) -and $_.NotAfter -gt (Get-Date) } | Select-Object -First 1
    if (-not $Existing -and $PSCmdlet.ShouldProcess($DnsName,'Create self-signed certificate')) { $Existing=New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation 'Cert:\LocalMachine\My' -FriendlyName $Friendly }
    $Existing | Select-Object Subject,Thumbprint,NotAfter
}
