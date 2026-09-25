#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Performance collector

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. An existing course collector is preserved unless -ReplaceCollector is explicitly supplied.

.CHANGES
Counter sampling and collector creation are explicit. Unavailable/localized counters are skipped cleanly.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Sample,
    [ValidateRange(1,300)][int]$SampleInterval = 5,
    [ValidateRange(1,1000)][int]$MaxSamples = 12,
    [switch]$CreateLogmanCollector,
    [switch]$ReplaceCollector
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Performance collector'

# Step 1: Validate the requested counters on this installation.
Write-Az802Step 1 'Validate performance counters'
$Candidates = @('\Processor(_Total)\% Processor Time','\Memory\Available MBytes','\PhysicalDisk(_Total)\Avg. Disk sec/Read','\PhysicalDisk(_Total)\Avg. Disk sec/Write')
$Valid = @()
foreach ($Counter in $Candidates) {
    try { Get-Counter $Counter -MaxSamples 1 -ErrorAction Stop | Out-Null; $Valid += $Counter }
    catch { Write-Az802Status WARN ('Skipping unavailable/localized counter: {0}' -f $Counter) }
}
if ($Valid.Count -eq 0) { Write-Az802Status SKIP 'No candidate performance counters were available.'; return }

# Step 2: Sample counters interactively when requested.
Write-Az802Step 2 'Optional repeated counter samples'
if ($Sample) { Get-Counter -Counter $Valid -SampleInterval $SampleInterval -MaxSamples $MaxSamples }

# Step 3: Create or deliberately replace a logman collector from validated counters.
Write-Az802Step 3 'Optional logman counter set'
if ($CreateLogmanCollector) {
    $Dir = 'C:\AZ802\PerfLogs'; Initialize-Az802Directory -Path $Dir
    $Name = 'AZ802-ServerPerf'
    & logman.exe query $Name *> $null
    $Exists = $LASTEXITCODE -eq 0
    if ($Exists -and -not $ReplaceCollector) {
        Write-Az802Status OK ('logman collector already exists: {0}. Use -ReplaceCollector to rebuild it deliberately.' -f $Name)
        return
    }
    if ($Exists -and $ReplaceCollector -and $PSCmdlet.ShouldProcess($Name,'Replace existing logman collector')) {
        Invoke-Az802Native 'logman.exe' @('stop',$Name) @(0,1) -WarnOnly | Out-Null
        Invoke-Az802Native 'logman.exe' @('delete',$Name) @(0) | Out-Null
        $Exists = $false
    }
    if (-not $Exists -and $PSCmdlet.ShouldProcess($Name,'Create logman collector')) {
        $Args = @('create','counter',$Name,'-c') + $Valid + @('-si',('00:00:{0:d2}' -f $SampleInterval),'-o',(Join-Path $Dir $Name))
        Invoke-Az802Native 'logman.exe' $Args @(0) | Out-Null
        Write-Az802Status OK ('Created logman collector {0}. Start/stop it deliberately with logman start/stop {0}.' -f $Name)
    }
}
