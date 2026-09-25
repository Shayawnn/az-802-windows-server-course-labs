#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 7 | Packet Monitor

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. The script does not stop an existing capture merely to start its own.

.CHANGES
Starts/stops only an explicit pktmon capture under C:\AZ802\Captures.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateRange(1,65535)][int]$Port = 445,
    [switch]$StartCapture,
    [switch]$StopCapture
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 7 | Packet Monitor'

# Step 1: Verify Packet Monitor availability and show current capture state.
Write-Az802Step 1 'Check pktmon availability and status'
if (-not (Get-Command pktmon.exe -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP 'pktmon.exe is not available on this Windows build.'; return }
$OutDir = 'C:\AZ802\Captures'; Initialize-Az802Directory -Path $OutDir
$Etl = Join-Path $OutDir 'PktMon.etl'
$Txt = Join-Path $OutDir 'PktMon.txt'
$StatusText = (& pktmon.exe status 2>&1 | Out-String)
$StatusCode = $LASTEXITCODE
$StatusText.Trim() | Write-Host
$CaptureAppearsActive = $StatusCode -eq 0 -and $StatusText -match '(?im)\b(running|active|capturing)\b'

# Step 2: Start a filtered capture only when requested and no capture appears to be active.
Write-Az802Step 2 'Optional packet capture'
if ($StartCapture) {
    if ($CaptureAppearsActive) { Write-Az802Status SKIP 'pktmon reports an active capture. It was not stopped or replaced automatically.' }
    else {
        Invoke-Az802Native 'pktmon.exe' @('filter','remove') @(0) | Out-Null
        Invoke-Az802Native 'pktmon.exe' @('filter','add','-p',[string]$Port) @(0) | Out-Null
        Invoke-Az802Native 'pktmon.exe' @('start','-c','--pkt-size','0','--file-name',$Etl) @(0) | Out-Null
        Write-Az802Status INFO ('Capture started for port {0}. Reproduce the issue, then rerun with -StopCapture.' -f $Port)
    }
}

# Step 3: Stop and convert a capture only when requested.
Write-Az802Step 3 'Optional capture stop and conversion'
if ($StopCapture) {
    Invoke-Az802Native 'pktmon.exe' @('stop') @(0,1) -WarnOnly | Out-Null
    if (Test-Path -LiteralPath $Etl) {
        Invoke-Az802Native 'pktmon.exe' @('etl2txt',$Etl,'--out',$Txt) @(0) | Out-Null
        Write-Az802Status OK ('Converted capture: {0}' -f $Txt)
    } else { Write-Az802Status INFO 'No AZ802 packet-capture ETL file exists to convert.' }
}
