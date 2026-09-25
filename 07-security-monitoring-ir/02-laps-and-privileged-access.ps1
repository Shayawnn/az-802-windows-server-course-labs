#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Windows LAPS and privileged access

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Schema extension requires two explicit switches. Password plaintext display is separately opt-in.

.CHANGES
Inspects LAPS. Optionally extends schema/configures course OU permissions and reads an explicit managed password.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$PrepareAD,
    [switch]$IUnderstandForestSchemaChange,
    [string[]]$AllowedPrincipals,
    [string]$ComputerName,
    [switch]$ShowPlainTextPassword
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Windows LAPS and privileged access'
# Step 1: Verify Windows LAPS tooling and domain context.
Write-Az802Step 1 'Inspect Windows LAPS prerequisites'
if (-not (Get-Module -ListAvailable LAPS)) { Write-Az802Status SKIP 'Windows LAPS PowerShell module is not available.'; return }
if (-not (Test-Az802Command Get-ADDomain)) { Write-Az802Status SKIP 'Active Directory PowerShell tools are not available.'; return }
Import-Module LAPS
Import-Module ActiveDirectory
$Domain=Get-ADDomain -ErrorAction SilentlyContinue
if (-not $Domain) { Write-Az802Status SKIP 'LAPS AD operations require Active Directory.'; return }
$ServersOu='OU=AZ802-Servers,{0}' -f $Domain.DistinguishedName
if (-not (Get-ADOrganizationalUnit -Identity $ServersOu -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP ('Course Servers OU not found: {0}' -f $ServersOu); return }

# Step 2: Extend schema and permissions only when explicitly requested.
Write-Az802Step 2 'Optional LAPS AD preparation'
if ($PrepareAD) {
    if (-not $IUnderstandForestSchemaChange) { throw 'Supply -IUnderstandForestSchemaChange before Update-LapsADSchema.' }
    if ($PSCmdlet.ShouldProcess($Domain.Forest,'Update Windows LAPS AD schema')) { Update-LapsADSchema }
    if ($PSCmdlet.ShouldProcess($ServersOu,'Grant computers permission to update their Windows LAPS password')) { Set-LapsADComputerSelfPermission -Identity $ServersOu }
    if ($AllowedPrincipals -and $PSCmdlet.ShouldProcess($ServersOu,('Grant LAPS password-read permission to {0}' -f ($AllowedPrincipals -join ', ')))) { Set-LapsADReadPasswordPermission -Identity $ServersOu -AllowedPrincipals $AllowedPrincipals }
}
Find-LapsADExtendedRights -Identity $ServersOu

# Step 3: Read a password only when a specific computer is supplied.
Write-Az802Step 3 'Optional LAPS password read'
if ($ComputerName) { Get-LapsADPassword -Identity $ComputerName -AsPlainText:$ShowPlainTextPassword }
