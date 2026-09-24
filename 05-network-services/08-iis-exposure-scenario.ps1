#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | IIS exposure scenario

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Uses only AZ802-Site and a harmless AZ802 demo file. The scenario explicitly enables directory browsing, observes it, then removes the file and disables browsing.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Build','Break','Observe','Repair','Verify')][string]$Phase = 'Observe'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | IIS exposure scenario'
if (-not (Test-Az802Command Get-Website)) { Write-Az802Status SKIP 'IIS management tools are not available.'; return }
Import-Module WebAdministration
$SiteName = 'AZ802-Site'
$Site = Get-Website -Name $SiteName -ErrorAction SilentlyContinue
if (-not $Site) { Write-Az802Status SKIP 'AZ802-Site does not exist. Build it with 04-iis.ps1 -CreateSite before running this scenario.'; return }
$SitePath = [Environment]::ExpandEnvironmentVariables([string]$Site.PhysicalPath)
$Folder = Join-Path $SitePath 'az802-download'
$DemoFile = Join-Path $Folder 'passwords-demo.txt'

# Step 1: Execute the requested controlled IIS phase.
Write-Az802Step 1 ('Scenario phase: {0}' -f $Phase)
switch ($Phase) {
    'Build' {
        if (-not (Test-Path -LiteralPath $Folder) -and $PSCmdlet.ShouldProcess($Folder,'Create the course exposure directory')) { New-Item -ItemType Directory -Path $Folder -Force | Out-Null }
        if ((Test-Path -LiteralPath $Folder) -and -not (Test-Path -LiteralPath $DemoFile) -and $PSCmdlet.ShouldProcess($DemoFile,'Create the harmless exposure-demo file')) { Set-Content -LiteralPath $DemoFile -Value 'DEMO ONLY - fake file for AZ-802 class.' }
        if (Test-Path -LiteralPath $DemoFile) { Write-Az802Status OK ('Harmless course file is ready: {0}' -f $DemoFile) }
        else { Write-Az802Status INFO 'Course exposure file was not created.' }
    }
    'Break' {
        if (-not (Test-Path -LiteralPath $DemoFile)) { throw 'Run -Phase Build first.' }
        if ($PSCmdlet.ShouldProcess($SiteName,'Enable directory browsing for the course scenario')) { Set-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -Value true -PSPath IIS:\ -Location $SiteName }
    }
    'Observe' {
        Get-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -PSPath IIS:\ -Location $SiteName
        Write-Az802Status INFO 'Request /az802-download/ and /az802-download/passwords-demo.txt from a browser when a client is available.'
    }
    'Repair' {
        if ($PSCmdlet.ShouldProcess($SiteName,'Disable directory browsing')) { Set-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -Value false -PSPath IIS:\ -Location $SiteName }
        if ((Test-Path -LiteralPath $DemoFile) -and $PSCmdlet.ShouldProcess($DemoFile,'Remove exposed demo file')) { Remove-Item -LiteralPath $DemoFile -Force }
    }
    'Verify' {
        $Enabled = [bool](Get-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -PSPath IIS:\ -Location $SiteName).Value
        Write-Az802Status INFO ('Directory browsing enabled: {0}' -f $Enabled)
        if (-not (Test-Path -LiteralPath $DemoFile) -and -not $Enabled) { Write-Az802Status OK 'The demo file is absent and directory browsing is disabled.' }
        else { Write-Az802Status WARN 'The scenario is not fully remediated yet.' }
    }
}
