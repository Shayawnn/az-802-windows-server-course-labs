#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Auditing and events

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. Audit-policy changes and event-log export are explicit opt-in actions.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$ConfigureLogonAuditing,
    [switch]$ShowAllAuditPolicy,
    [switch]$Export
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Auditing and events'
# Step 1: Inspect audit policy and optionally enable the course logon-auditing examples.
Write-Az802Step 1 'Inspect audit policy'
if ($ShowAllAuditPolicy) {
    & auditpol.exe '/get' '/category:*'
    if ($LASTEXITCODE -ne 0) { Write-Az802Status WARN ('auditpol /get returned exit code {0}.' -f $LASTEXITCODE) }
}
& auditpol.exe '/get' '/subcategory:Logon'
if ($LASTEXITCODE -ne 0) { Write-Az802Status WARN ('auditpol /get Logon returned exit code {0}.' -f $LASTEXITCODE) }
if ($ConfigureLogonAuditing -and $PSCmdlet.ShouldProcess('Local advanced audit policy','Enable success/failure auditing for course logon-related subcategories')) {
    foreach ($Subcategory in @('Logon','Account Lockout','User Account Management')) {
        Invoke-Az802Native -FilePath 'auditpol.exe' -ArgumentList @('/set',('/subcategory:{0}' -f $Subcategory),'/success:enable','/failure:enable') | Out-Null
        Write-Az802Status CHANGE ('Enabled success/failure auditing for {0}.' -f $Subcategory)
    }
    & auditpol.exe '/get' '/subcategory:Logon'
    if ($LASTEXITCODE -ne 0) { Write-Az802Status WARN ('auditpol verification returned exit code {0}.' -f $LASTEXITCODE) }
    Write-Az802Status WARN 'Domain Group Policy can overwrite local audit policy. If the setting changes back, inspect the applicable GPOs.'
} else {
    Write-Az802Status INFO 'Use -ConfigureLogonAuditing to enable the three course logon-related audit subcategories.'
}

# Step 2: Read recent authentication and service events.
Write-Az802Step 2 'Read focused Security and System events'
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625;StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue | Select-Object -First 20 TimeCreated,Id,Message
Get-WinEvent -FilterHashtable @{LogName='System';Id=7036,7031,7034;StartTime=(Get-Date).AddHours(-12)} -ErrorAction SilentlyContinue | Select-Object TimeCreated,Id,ProviderName,Message

# Step 3: Export event logs to a course evidence directory when requested.
Write-Az802Step 3 'Optional event-log export'
if ($Export) {
    $Dir='C:\AZ802\Evidence\EventLogs'; Initialize-Az802Directory -Path $Dir
    foreach ($Log in @('Security','System','Application')) { Invoke-Az802Native -FilePath 'wevtutil.exe' -ArgumentList @('epl',$Log,(Join-Path $Dir ($Log+'.evtx')),'/ow:true') | Out-Null }
    $DefenderLog='Microsoft-Windows-Windows Defender/Operational'
    if (Get-WinEvent -ListLog $DefenderLog -ErrorAction SilentlyContinue) { Invoke-Az802Native -FilePath 'wevtutil.exe' -ArgumentList @('epl',$DefenderLog,(Join-Path $Dir 'Defender.evtx'),'/ow:true') -AllowedExitCodes @(0,1) -WarnOnly | Out-Null }
    Get-ChildItem $Dir -Filter '*.evtx'
}
