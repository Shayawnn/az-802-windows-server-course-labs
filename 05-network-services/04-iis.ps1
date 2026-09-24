#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | IIS

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspects IIS by default. Installation and course-scoped site/firewall creation are explicit and existing bindings are validated before reuse.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [switch]$CreateSite,
    [ValidateRange(1,65535)][int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | IIS'

# Step 1: Inspect or install IIS.
Write-Az802Step 1 'Inspect IIS state'
$Role = Get-WindowsFeature Web-Server
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install IIS')) {
    Install-WindowsFeature Web-Server -IncludeManagementTools | Out-Host
}
if (-not (Get-WindowsFeature Web-Server).Installed) { Write-Az802Status SKIP 'IIS is not installed.'; return }
Import-Module WebAdministration
Get-Service W3SVC
Get-Website

# Step 2: Build a course-scoped site only when requested.
Write-Az802Step 2 'Optional course website'
if ($CreateSite) {
    $SiteName = 'AZ802-Site'
    $SitePath = 'C:\AZ802\Web\Site'
    $ExpectedBinding = '*:{0}:' -f $Port
    $ExistingSite = Get-Website -Name $SiteName -ErrorAction SilentlyContinue

    if ($ExistingSite) {
        if ([IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables([string]$ExistingSite.PhysicalPath)).TrimEnd('\') -ine [IO.Path]::GetFullPath($SitePath).TrimEnd('\')) {
            throw ('{0} exists with physical path {1}; expected {2}. Refusing to repurpose it.' -f $SiteName,$ExistingSite.PhysicalPath,$SitePath)
        }
        $SiteBindings = @(Get-WebBinding -Name $SiteName -Protocol http -ErrorAction SilentlyContinue)
        if (-not ($SiteBindings | Where-Object bindingInformation -eq $ExpectedBinding)) {
            throw ('{0} exists but does not have the expected HTTP binding {1}. Reconcile it deliberately before continuing.' -f $SiteName,$ExpectedBinding)
        }
    } else {
        $PortConflict = @(Get-WebBinding -Protocol http -ErrorAction SilentlyContinue | Where-Object {
            $Parts = $_.bindingInformation -split ':',3
            $Parts.Count -ge 2 -and $Parts[1] -eq [string]$Port
        })
        if ($PortConflict.Count -gt 0) { throw ('HTTP port {0} is already used by another IIS binding. Choose a different -Port.' -f $Port) }
        Initialize-Az802Directory -Path $SitePath
        if ($PSCmdlet.ShouldProcess($SiteName,'Create IIS site')) {
            New-Website -Name $SiteName -Port $Port -PhysicalPath $SitePath | Out-Null
            $ExistingSite = Get-Website -Name $SiteName -ErrorAction Stop
        }
    }

    if (-not (Test-Path -LiteralPath $SitePath)) { Initialize-Az802Directory -Path $SitePath }
    $IndexPath = Join-Path $SitePath 'index.html'
    if (-not (Test-Path -LiteralPath $IndexPath)) { Set-Content -LiteralPath $IndexPath -Value 'AZ-802 IIS Lab - The web server is working.' }

    $RuleName = 'AZ802-IIS-HTTP-{0}' -f $Port
    $Rule = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
    if ($Rule) {
        $PortFilter = $Rule | Get-NetFirewallPortFilter
        if ($PortFilter.Protocol -ne 'TCP' -or [string]$PortFilter.LocalPort -ne [string]$Port) { throw ('Firewall rule {0} exists with an unexpected protocol or port.' -f $RuleName) }
    } elseif ($PSCmdlet.ShouldProcess($RuleName,'Create IIS firewall rule')) {
        New-NetFirewallRule -Name $RuleName -DisplayName ('AZ802 | IIS HTTP {0}' -f $Port) -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
    }

    try {
        Invoke-WebRequest ('http://localhost:{0}/' -f $Port) -UseBasicParsing -ErrorAction Stop | Select-Object StatusCode,StatusDescription
        Write-Az802Status OK ('AZ802-Site answered on HTTP/{0}.' -f $Port)
    } catch {
        Write-Az802Status WARN ('The site configuration exists, but the local HTTP request did not succeed: {0}' -f $_.Exception.Message)
    }
}
