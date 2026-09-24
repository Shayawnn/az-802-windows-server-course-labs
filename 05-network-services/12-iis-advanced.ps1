#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | Advanced IIS operations

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Advanced IIS changes are opt-in and target explicit course/application locations.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$CreateVirtualDirectory,
    [switch]$EnableWindowsAuthentication,
    [string]$Location,
    [switch]$EnableHsts,
    [string]$SiteName = 'AZ802-Site',
    [ValidateRange(0,2147483647)][int]$HstsMaxAge = 31536000
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | Advanced IIS operations'
if (-not (Test-Az802Command Get-Website)) { Write-Az802Status SKIP 'IIS management tools are not available.'; return }
Import-Module WebAdministration
if (-not (Get-WindowsFeature Web-Server).Installed) { Write-Az802Status SKIP 'IIS is not installed.'; return }

# Step 1: Create a course virtual directory only when requested.
Write-Az802Step 1 'Optional virtual directory'
if ($CreateVirtualDirectory) {
    if (-not (Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) { Write-Az802Status SKIP ('IIS site not found: {0}. Build AZ802-Site with 04-iis.ps1 or supply an explicit existing -SiteName.' -f $SiteName); return }
    $Path='C:\AZ802\Web\VirtualDir'
    if (-not (Test-Path -LiteralPath $Path) -and $PSCmdlet.ShouldProcess($Path,'Create course virtual-directory content path')) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    $Index = Join-Path $Path 'index.html'; if ((Test-Path -LiteralPath $Path) -and -not (Test-Path -LiteralPath $Index) -and $PSCmdlet.ShouldProcess($Index,'Create virtual-directory test page')) { Set-Content -LiteralPath $Index -Value 'AZ-802 Virtual Directory Test Page' }
    $ExistingVdir = Get-WebVirtualDirectory -Site $SiteName -Name 'az802-vdir' -ErrorAction SilentlyContinue
    if ($ExistingVdir -and $ExistingVdir.PhysicalPath -ne $Path) { throw 'az802-vdir already exists with an unexpected physical path.' }
    if (-not $ExistingVdir -and $PSCmdlet.ShouldProcess('az802-vdir',('Create IIS virtual directory under {0}' -f $SiteName))) { New-WebVirtualDirectory -Site $SiteName -Name 'az802-vdir' -PhysicalPath $Path | Out-Null }
}

# Step 2: Configure Windows Authentication only on an explicit existing site/application path.
Write-Az802Step 2 'Optional Windows Authentication'
if ($EnableWindowsAuthentication) {
    if (-not $Location) { throw 'Supply -Location using IIS location syntax, for example "AZ802-Site/az802-vdir".' }
    if (-not (Get-WindowsFeature Web-Windows-Auth).Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install Windows Authentication role service')) { Install-WindowsFeature Web-Windows-Auth | Out-Host }
    if ($PSCmdlet.ShouldProcess($Location,'Enable Windows Authentication and disable Anonymous Authentication')) {
        Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Location $Location -Name enabled -Value $false
        Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/windowsAuthentication' -Location $Location -Name enabled -Value $true
    }
}

# Step 3: Configure native IIS HSTS only on an explicit existing site.
Write-Az802Step 3 'Optional HSTS configuration'
if ($EnableHsts) {
    if (-not (Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) { throw ('IIS site not found: {0}' -f $SiteName) }
    $Filter="system.applicationHost/sites/site[@name='$SiteName']/hsts"
    if ($PSCmdlet.ShouldProcess($SiteName,'Enable HSTS')) {
        Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $Filter -Name enabled -Value $true
        Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $Filter -Name 'max-age' -Value $HstsMaxAge
    }
    Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $Filter -Name enabled
    Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $Filter -Name 'max-age'
}
