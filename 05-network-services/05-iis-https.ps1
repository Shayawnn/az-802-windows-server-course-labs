#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | IIS HTTPS

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only unless -Create is supplied. Creates or reuses a course certificate and an exact SNI HTTPS binding on the requested site, host and port.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$SiteName = 'AZ802-Site',
    [string]$HostName,
    [ValidateRange(1,65535)][int]$Port = 8443,
    [string]$CertificateFriendlyName = 'AZ802 IIS Lab',
    [switch]$Create
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | IIS HTTPS'
if (-not (Test-Az802Command Get-Website)) { Write-Az802Status SKIP 'IIS management tools are not available.'; return }
Import-Module WebAdministration
$Site = Get-Website -Name $SiteName -ErrorAction SilentlyContinue
if (-not $Site) { Write-Az802Status SKIP ('IIS site not found: {0}' -f $SiteName); return }
if (-not $HostName) { $HostName = $env:COMPUTERNAME }
$ExpectedBinding = '*:{0}:{1}' -f $Port,$HostName

# Step 1: Create or reuse a course self-signed certificate for the requested host.
Write-Az802Step 1 'Create or verify the course TLS certificate'
$Cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {
    $_.FriendlyName -eq $CertificateFriendlyName -and
    $_.NotAfter -gt (Get-Date) -and
    (($_.Subject -eq ('CN={0}' -f $HostName)) -or ($_.DnsNameList.Unicode -contains $HostName))
} | Sort-Object NotAfter -Descending | Select-Object -First 1
if (-not $Cert -and $Create -and $PSCmdlet.ShouldProcess($HostName,'Create self-signed IIS certificate')) {
    $Cert = New-SelfSignedCertificate -DnsName $HostName -CertStoreLocation 'Cert:\LocalMachine\My' -FriendlyName $CertificateFriendlyName
}
if (-not $Cert) { Write-Az802Status INFO ('No matching course certificate exists for {0}. Use -Create to create and bind one.' -f $HostName); return }
Write-Az802Status OK ('Certificate: {0} | expires {1}' -f $Cert.Thumbprint,$Cert.NotAfter)

# Step 2: Create or verify the exact HTTPS binding.
Write-Az802Step 2 'Create or verify HTTPS binding'
$Binding = Get-WebBinding -Name $SiteName -Protocol https -ErrorAction SilentlyContinue | Where-Object bindingInformation -eq $ExpectedBinding | Select-Object -First 1
if (-not $Binding) {
    $Conflict = Get-WebBinding -Protocol https -ErrorAction SilentlyContinue | Where-Object bindingInformation -eq $ExpectedBinding | Select-Object -First 1
    if ($Conflict) { throw ('HTTPS binding {0} is already owned by another IIS site.' -f $ExpectedBinding) }
    if ($Create -and $PSCmdlet.ShouldProcess($SiteName,('Create HTTPS binding {0}' -f $ExpectedBinding))) {
        New-WebBinding -Name $SiteName -Protocol https -Port $Port -HostHeader $HostName -SslFlags 1 | Out-Null
        $Binding = Get-WebBinding -Name $SiteName -Protocol https | Where-Object bindingInformation -eq $ExpectedBinding | Select-Object -First 1
    }
}
if ($Binding -and $Create -and $PSCmdlet.ShouldProcess($ExpectedBinding,('Bind certificate {0}' -f $Cert.Thumbprint))) {
    $Binding.AddSslCertificate($Cert.Thumbprint,'My')
}
Get-WebBinding -Name $SiteName | Select-Object protocol,bindingInformation,sslFlags
