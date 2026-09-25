#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Incident-response evidence

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Creates a timestamped read-only evidence bundle under C:\AZ802\Evidence.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Incident-response evidence'
$Dir=Join-Path 'C:\AZ802\Evidence' (Get-Date -Format 'yyyyMMdd-HHmmss')
Initialize-Az802Directory -Path $Dir
# Step 1: Capture host, identity and network state.
Write-Az802Step 1 'Capture host and network evidence'
hostname.exe | Out-File (Join-Path $Dir 'host.txt')
whoami.exe /all | Out-File (Join-Path $Dir 'whoami.txt')
ipconfig.exe /all | Out-File (Join-Path $Dir 'ipconfig.txt')
route.exe print | Out-File (Join-Path $Dir 'routes.txt')
netstat.exe -ano | Out-File (Join-Path $Dir 'netstat.txt')
tasklist.exe /svc | Out-File (Join-Path $Dir 'tasklist.txt')
schtasks.exe /query /fo LIST /v | Out-File (Join-Path $Dir 'scheduled-tasks.txt')

# Step 2: Export core event logs before changing anything.
Write-Az802Step 2 'Export core event logs'
foreach ($Log in @('Security','System','Application')) { Invoke-Az802Native 'wevtutil.exe' @('epl',$Log,(Join-Path $Dir ($Log+'.evtx'))) @(0,1) -WarnOnly | Out-Null }

# Step 3: Collect recent security-relevant changes and persistence state.
Write-Az802Step 3 'Collect recent account and persistence signals'
$Start=(Get-Date).AddDays(-7); $Ids=4720,4722,4723,4724,4725,4726,4732,4733,4756,4757,4740,4672
Get-WinEvent -FilterHashtable @{LogName='Security';Id=$Ids;StartTime=$Start} -ErrorAction SilentlyContinue | Select-Object TimeCreated,Id,Message | Export-Clixml (Join-Path $Dir 'security-account-events.xml')
Get-Service | Sort-Object StartType,Status,Name | Export-Csv (Join-Path $Dir 'services.csv') -NoTypeInformation
Get-ScheduledTask | Where-Object State -ne Disabled | Export-Csv (Join-Path $Dir 'scheduled-tasks.csv') -NoTypeInformation
Get-CimInstance Win32_StartupCommand | Export-Csv (Join-Path $Dir 'startup-commands.csv') -NoTypeInformation
Write-Az802Status OK ('Evidence bundle created: {0}' -f $Dir)
