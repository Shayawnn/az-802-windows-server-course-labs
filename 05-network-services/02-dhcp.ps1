#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | DHCP

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Inspects DHCP by default. Installation, AD authorization, scope creation and options are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [switch]$AuthorizeInAD,
    [string]$ScopeName,
    [string]$StartRange,
    [string]$EndRange,
    [string]$SubnetMask,
    [string[]]$DnsServers,
    [string]$Router,
    [string]$DnsDomain
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | DHCP'
# Step 1: Inspect or install the DHCP role.
Write-Az802Step 1 'Inspect DHCP Server state'
$Role = Get-WindowsFeature DHCP
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install DHCP Server')) { Install-WindowsFeature DHCP -IncludeManagementTools | Out-Host }
if (-not (Get-WindowsFeature DHCP).Installed) { Write-Az802Status SKIP 'DHCP Server is not installed.'; return }
Import-Module DhcpServer
Get-Service DHCPServer
Get-DhcpServerv4Scope -ErrorAction SilentlyContinue

# Step 2: Authorize the current DHCP server in AD only when requested and when a domain exists.
Write-Az802Step 2 'Optional AD authorization'
$Context = Get-Az802DomainContext
if ($AuthorizeInAD) {
    if (-not $Context.PartOfDomain) { throw 'DHCP authorization in AD requires domain membership.' }
    $Fqdn = '{0}.{1}' -f $env:COMPUTERNAME,$Context.DnsRoot
    $Address = Get-Az802PrimaryIPv4
    if (-not $Address) { throw 'Could not determine the current primary IPv4 address.' }
    $Authorized = Get-DhcpServerInDC -ErrorAction SilentlyContinue | Where-Object DnsName -ieq $Fqdn
    if (-not $Authorized -and $PSCmdlet.ShouldProcess($Fqdn,'Authorize DHCP server in AD')) { Add-DhcpServerInDC -DnsName $Fqdn -IPAddress $Address | Out-Null }
}

# Step 3: Create a scope only from explicit range values.
Write-Az802Step 3 'Optional IPv4 scope creation'
if ($StartRange -or $EndRange -or $SubnetMask) {
    if (-not ($StartRange -and $EndRange -and $SubnetMask -and $ScopeName)) { throw 'ScopeName, StartRange, EndRange and SubnetMask must be supplied together.' }
    $ExistingByName = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue | Where-Object Name -eq $ScopeName
    if (-not $ExistingByName -and $PSCmdlet.ShouldProcess($ScopeName,'Create DHCP scope')) { Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask -LeaseDuration ([TimeSpan]::FromHours(8)) -State Active | Out-Null }
    $Scope = Get-DhcpServerv4Scope | Where-Object Name -eq $ScopeName | Select-Object -First 1
    if (-not $Scope) { throw 'Scope creation did not produce a retrievable scope.' }
    Write-Az802Status OK ('Resolved scope ID: {0}' -f $Scope.ScopeId)
    if ($DnsServers -or $Router -or $DnsDomain) {
        $Args = @{ ScopeId = $Scope.ScopeId }
        if ($DnsServers) { $Args.DnsServer = $DnsServers }
        if ($Router) { $Args.Router = $Router }
        if ($DnsDomain) { $Args.DnsDomain = $DnsDomain }
        if ($PSCmdlet.ShouldProcess($Scope.ScopeId,'Set DHCP scope options')) { Set-DhcpServerv4OptionValue @Args }
    }
    Get-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId
}
