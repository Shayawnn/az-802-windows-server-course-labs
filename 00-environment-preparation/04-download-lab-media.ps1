#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Download and verify optional Ubuntu Server lab media.

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. An existing ISO is verified against the current official SHA-256 manifest before it is reused.

.CHANGES
Optionally downloads the current Ubuntu 24.04 LTS server ISO from releases.ubuntu.com. Windows Server media must be supplied explicitly.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$DownloadUbuntu
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Environment preparation | Lab media'
$Config = Import-Az802Config -RepoRoot $RepoRoot
$Media = Join-Path $Config.LabRoot 'Media'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Step 1: Discover the current Ubuntu 24.04 LTS server image and its official hash when requested.
Write-Az802Step 1 'Discover Ubuntu Server LTS media'
if ($DownloadUbuntu) {
    $ReleaseRoot = 'https://releases.ubuntu.com/24.04/'
    $Html = (Invoke-WebRequest -Uri $ReleaseRoot -UseBasicParsing).Content
    $Matches = [regex]::Matches($Html,'ubuntu-24\.04\.\d+-live-server-amd64\.iso') | ForEach-Object Value | Sort-Object -Unique
    if (-not $Matches) { throw 'Could not discover the current Ubuntu 24.04 LTS server ISO from the official release page.' }
    $IsoName = $Matches | Sort-Object { [version](($_ -replace '^ubuntu-','' -replace '-live-server-amd64\.iso$','')) } -Descending | Select-Object -First 1
    $IsoPath = Join-Path $Media $IsoName
    $Manifest = (Invoke-WebRequest -Uri ($ReleaseRoot + 'SHA256SUMS') -UseBasicParsing).Content -split '\r?\n'
    $ExpectedLine = $Manifest | Where-Object { $_ -match [regex]::Escape($IsoName) } | Select-Object -First 1
    if (-not $ExpectedLine) { throw 'Official SHA256SUMS does not contain the discovered ISO name.' }
    $Expected = ($ExpectedLine -split '\s+')[0].ToUpperInvariant()

    $NeedDownload = $true
    if (Test-Path -LiteralPath $IsoPath) {
        $ExistingHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $IsoPath).Hash.ToUpperInvariant()
        if ($ExistingHash -eq $Expected) {
            $NeedDownload = $false
            Write-Az802Status OK ('Existing Ubuntu ISO is verified: {0}' -f $IsoPath)
        } else {
            Write-Az802Status WARN 'Existing Ubuntu ISO does not match the official SHA-256 and will be replaced if approved.'
        }
    }
    if ($NeedDownload -and $PSCmdlet.ShouldProcess($IsoPath,'Download verified Ubuntu Server ISO')) {
        Initialize-Az802Directory -Path $Media
        Invoke-WebRequest -Uri ($ReleaseRoot + $IsoName) -OutFile $IsoPath -UseBasicParsing
        $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $IsoPath).Hash.ToUpperInvariant()
        if ($Actual -ne $Expected) { Remove-Item -LiteralPath $IsoPath -Force; throw 'Ubuntu ISO SHA-256 verification failed.' }
        Write-Az802Status OK ('Downloaded and verified Ubuntu ISO: {0}' -f $IsoPath)
    }
} else {
    Write-Az802Status SKIP 'Ubuntu ISO download was not requested.'
}

# Step 2: Check the configured Windows Server media path without guessing a licensing URL.
Write-Az802Step 2 'Check Windows Server media configuration'
if ($Config.WindowsServerIso -and (Test-Path -LiteralPath $Config.WindowsServerIso)) {
    Write-Az802Status OK ('Configured Windows Server ISO exists: {0}' -f $Config.WindowsServerIso)
} elseif ($Config.WindowsServerIso) {
    Write-Az802Status WARN ('Configured Windows Server ISO was not found: {0}' -f $Config.WindowsServerIso)
} else {
    Write-Az802Status INFO 'Windows Server media is not downloaded automatically. Put a licensed/evaluation ISO on disk and set WindowsServerIso in config\LabConfig.psd1.'
}
