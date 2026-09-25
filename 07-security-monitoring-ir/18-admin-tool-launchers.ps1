#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Administrative tool launchers

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Nothing opens unless its matching switch is supplied.

.CHANGES
Launches the requested built-in Windows administration interface. It does not change Windows Update, event-log or performance settings by itself.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$WindowsUpdate,
    [switch]$SConfig,
    [switch]$EventViewer,
    [switch]$ReliabilityMonitor
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Administrative tool launchers'
$DesktopExperience = Test-Path -LiteralPath (Join-Path $env:WINDIR 'explorer.exe')

# Step 1: Show which built-in administration interfaces are available on this server.
Write-Az802Step 1 'Inspect available administration tools'
Write-Az802Status INFO ('Desktop Experience: {0}' -f $DesktopExperience)
foreach ($CommandName in @('SConfig','eventvwr.msc','perfmon.exe')) {
    $Command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($Command) { Write-Az802Status OK ('Available: {0}' -f $CommandName) }
    else { Write-Az802Status SKIP ('Not available here: {0}' -f $CommandName) }
}

# Step 2: Open Windows Update settings when Desktop Experience is available.
Write-Az802Step 2 'Optional Windows Update settings'
if ($WindowsUpdate) {
    if (-not $DesktopExperience) { Write-Az802Status SKIP 'The modern Settings application is not available on Server Core.' }
    elseif ($PSCmdlet.ShouldProcess('ms-settings:windowsupdate','Open Windows Update settings')) {
        # PowerShell console equivalent: start ms-settings:windowsupdate
        Start-Process 'ms-settings:windowsupdate'
        Write-Az802Status OK 'Opened Windows Update settings.'
    }
} else { Write-Az802Status INFO 'Use -WindowsUpdate to open the Windows Update settings page.' }

# Step 3: Open SConfig when requested.
Write-Az802Step 3 'Optional SConfig'
if ($SConfig) {
    $Command = Get-Command SConfig -ErrorAction SilentlyContinue
    if (-not $Command) { Write-Az802Status SKIP 'SConfig is not available on this Windows Server build.' }
    elseif ($PSCmdlet.ShouldProcess('SConfig','Open Server Configuration')) {
        & ($Command.Name)
    }
} else { Write-Az802Status INFO 'Use -SConfig to open Server Configuration.' }

# Step 4: Open Event Viewer when the graphical console is available.
Write-Az802Step 4 'Optional Event Viewer'
if ($EventViewer) {
    if (-not $DesktopExperience) { Write-Az802Status SKIP 'Event Viewer GUI is not available on Server Core. Use Get-WinEvent or wevtutil instead.' }
    elseif (-not (Get-Command 'eventvwr.msc' -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP 'eventvwr.msc is not available.' }
    elseif ($PSCmdlet.ShouldProcess('Event Viewer','Open eventvwr.msc')) {
        Start-Process 'eventvwr.msc'
        Write-Az802Status OK 'Opened Event Viewer.'
    }
} else { Write-Az802Status INFO 'Use -EventViewer to open Event Viewer.' }

# Step 5: Open Reliability Monitor when the graphical performance tools are available.
Write-Az802Step 5 'Optional Reliability Monitor'
if ($ReliabilityMonitor) {
    if (-not $DesktopExperience) { Write-Az802Status SKIP 'Reliability Monitor GUI is not available on Server Core.' }
    elseif (-not (Get-Command 'perfmon.exe' -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP 'perfmon.exe is not available.' }
    elseif ($PSCmdlet.ShouldProcess('Reliability Monitor','Open perfmon /rel')) {
        Start-Process 'perfmon.exe' -ArgumentList '/rel'
        Write-Az802Status OK 'Opened Reliability Monitor.'
    }
} else { Write-Az802Status INFO 'Use -ReliabilityMonitor to open Reliability Monitor.' }
