#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | DNS failure scenario

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Only the AZ802 course record is used by default. Build saves a visible repair baseline before Break is allowed.

.CHANGES
Runs a reversible DNS A-record failure scenario.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Build','Break','Observe','Repair','Verify')][string]$Phase = 'Observe',
    [string]$ZoneName,
    [string]$RecordName = 'az802-intranet',
    [string]$GoodAddress,
    [string]$BadAddress
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | DNS failure scenario'
if (-not (Test-Az802Command Get-DnsServerZone)) { Write-Az802Status SKIP 'DNS Server management tools are not available.'; return }
Import-Module DnsServer
$Context = Get-Az802DomainContext
if (-not $ZoneName) { $ZoneName = $Context.DnsRoot }
if (-not $ZoneName) { Write-Az802Status SKIP 'No domain/zone was detected. Supply -ZoneName explicitly.'; return }
if (-not (Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP ('DNS zone not found: {0}' -f $ZoneName); return }
$StateDir = 'C:\AZ802\State'
$StateFile = Join-Path $StateDir 'dns-failure-baseline.json'

# Step 1: Execute the requested phase against one course-scoped A record.
Write-Az802Step 1 ('Scenario phase: {0}' -f $Phase)
switch ($Phase) {
    'Build' {
        if (-not (Test-Path -LiteralPath $StateDir) -and $PSCmdlet.ShouldProcess($StateDir,'Create the scenario state directory')) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
        if (-not $GoodAddress) { $GoodAddress = Get-Az802PrimaryIPv4 }
        if (-not $GoodAddress) { throw 'Supply -GoodAddress.' }
        $Existing = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $RecordName -RRType A -ErrorAction SilentlyContinue
        if ($Existing) {
            $Current = [string]$Existing.RecordData.IPv4Address
            if ($Current -ne $GoodAddress) { throw ('Existing record points to {0}. Use a different RecordName or repair it deliberately.' -f $Current) }
        } elseif ($PSCmdlet.ShouldProcess($RecordName,'Create clean scenario record')) { Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name $RecordName -IPv4Address $GoodAddress | Out-Null }
        $Ready = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $RecordName -RRType A -ErrorAction SilentlyContinue
        if (-not $Ready -or [string]$Ready.RecordData.IPv4Address -ne $GoodAddress) { Write-Az802Status INFO 'Clean record is not present yet; no repair baseline was written.'; return }
        if ($PSCmdlet.ShouldProcess($StateFile,'Save the DNS repair baseline')) {
            @{ZoneName=$ZoneName;RecordName=$RecordName;GoodAddress=$GoodAddress} | ConvertTo-Json | Set-Content -LiteralPath $StateFile
        }
        if (Test-Path -LiteralPath $StateFile) { Write-Az802Status OK ('Clean record and repair baseline are ready: {0}.{1} -> {2}' -f $RecordName,$ZoneName,$GoodAddress) }
    }
    'Break' {
        if (-not $BadAddress) { throw 'Supply -BadAddress for the controlled redirect.' }
        if (-not (Test-Path $StateFile)) { throw 'Run -Phase Build first so the original address is recorded.' }
        $Baseline = Get-Content $StateFile -Raw | ConvertFrom-Json
        $Old = Get-DnsServerResourceRecord -ZoneName $Baseline.ZoneName -Name $Baseline.RecordName -RRType A -ErrorAction Stop
        $New = $Old.Clone(); $New.RecordData.IPv4Address = [System.Net.IPAddress]$BadAddress
        if ($PSCmdlet.ShouldProcess($Baseline.RecordName,('Redirect A record to {0}' -f $BadAddress))) { Set-DnsServerResourceRecord -ZoneName $Baseline.ZoneName -OldInputObject $Old -NewInputObject $New }
    }
    'Observe' { Resolve-DnsName ('{0}.{1}' -f $RecordName,$ZoneName) -Server 127.0.0.1; Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $RecordName -RRType A }
    'Repair' {
        if (-not (Test-Path $StateFile)) { throw 'Repair baseline is missing; refusing to guess the original address.' }
        $Baseline = Get-Content $StateFile -Raw | ConvertFrom-Json
        $Old = Get-DnsServerResourceRecord -ZoneName $Baseline.ZoneName -Name $Baseline.RecordName -RRType A -ErrorAction Stop
        $New = $Old.Clone(); $New.RecordData.IPv4Address = [System.Net.IPAddress]$Baseline.GoodAddress
        if ($PSCmdlet.ShouldProcess($Baseline.RecordName,('Restore A record to {0}' -f $Baseline.GoodAddress))) { Set-DnsServerResourceRecord -ZoneName $Baseline.ZoneName -OldInputObject $Old -NewInputObject $New }
    }
    'Verify' {
        $Answer = Resolve-DnsName ('{0}.{1}' -f $RecordName,$ZoneName) -Server 127.0.0.1 -ErrorAction Stop | Where-Object Type -eq A | Select-Object -First 1
        $Answer | Format-Table Name,Type,IPAddress
        if (Test-Path $StateFile) { $Baseline=Get-Content $StateFile -Raw|ConvertFrom-Json; if ($Answer.IPAddress -eq $Baseline.GoodAddress) { Write-Az802Status OK 'DNS record matches the saved clean baseline.' } else { Write-Az802Status WARN 'DNS answer does not match the saved clean baseline.' } }
    }
}
