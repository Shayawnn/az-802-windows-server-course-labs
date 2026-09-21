#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Install or verify Sysinternals Suite in the course tools directory.

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. An existing course copy is reused unless -Refresh is supplied.

.CHANGES
Downloads the official Sysinternals Suite archive and expands it under the course root.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Refresh
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Environment preparation | Sysinternals'
$Config = Import-Az802Config -RepoRoot $RepoRoot
$Destination = Join-Path $Config.LabRoot 'Tools\Sysinternals'
$ProcessExplorer = Join-Path $Destination 'procexp64.exe'
$ZipPath = Join-Path $env:TEMP 'AZ802-SysinternalsSuite.zip'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Step 1: Reuse an existing course copy when it is already present.
Write-Az802Step 1 'Check the existing Sysinternals installation'
if ((Test-Path -LiteralPath $ProcessExplorer) -and -not $Refresh) {
    Write-Az802Status OK ('Sysinternals is already available at {0}.' -f $Destination)
    return
}

# Step 2: Download the official Sysinternals archive when installation is approved.
Write-Az802Step 2 'Download Sysinternals Suite'
if (-not $PSCmdlet.ShouldProcess($Destination,'Download, verify and install Sysinternals Suite')) { return }
Initialize-Az802Directory -Path (Split-Path -Parent $Destination)
Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/SysinternalsSuite.zip' -OutFile $ZipPath -UseBasicParsing
if (-not (Test-Path -LiteralPath $ZipPath)) { throw 'Sysinternals download did not create the expected archive.' }

# Step 3: Expand and verify the archive before replacing the course copy.
Write-Az802Step 3 'Expand and verify Sysinternals Suite'
$Staging = $Destination + '.staging'
if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force }
Expand-Archive -LiteralPath $ZipPath -DestinationPath $Staging -Force
$StagedProcessExplorer = Join-Path $Staging 'procexp64.exe'
if (-not (Test-Path -LiteralPath $StagedProcessExplorer)) { throw 'Downloaded archive did not contain Process Explorer at the expected path.' }
$Signature = Get-AuthenticodeSignature -FilePath $StagedProcessExplorer
if ($Signature.Status -ne 'Valid' -or [string]$Signature.SignerCertificate.Subject -notmatch 'Microsoft') {
    Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
    throw ('Process Explorer did not have the expected valid Microsoft signature. Signature status: {0}' -f $Signature.Status)
}
if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Recurse -Force }
Move-Item -LiteralPath $Staging -Destination $Destination
Write-Az802Status OK ('Sysinternals is ready at {0}.' -f $Destination)
