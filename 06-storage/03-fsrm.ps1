#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | File Server Resource Manager

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Read-only by default. FSRM installation and the AZ802 course quota/template are explicit.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Install,
    [switch]$CreateQuota
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | File Server Resource Manager'
# Step 1: Inspect or install FSRM.
Write-Az802Step 1 'Inspect FSRM state'
$Role=Get-WindowsFeature FS-Resource-Manager
$Role
if ($Install -and -not $Role.Installed -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Install FSRM')) { Install-WindowsFeature FS-Resource-Manager -IncludeManagementTools | Out-Host }
if (-not (Get-WindowsFeature FS-Resource-Manager).Installed) { Write-Az802Status SKIP 'FSRM is not installed.'; return }

# Step 2: Create or verify the course quota template and quota.
Write-Az802Step 2 'Optional course quota'
if ($CreateQuota) {
    $Template='AZ802-5GB-Limit'
    $ExistingTemplate=Get-FsrmQuotaTemplate -Name $Template -ErrorAction SilentlyContinue
    if ($ExistingTemplate -and $ExistingTemplate.Size -ne 5GB) { throw 'AZ802 quota template exists with an unexpected size.' }
    if (-not $ExistingTemplate -and $PSCmdlet.ShouldProcess($Template,'Create 5GB quota template')) { New-FsrmQuotaTemplate -Name $Template -Size 5GB -Description 'AZ-802 course quota template' | Out-Null }
    $Path='C:\AZ802\Shares\Share01'; Initialize-Az802Directory -Path $Path
    $ExistingQuota=Get-FsrmQuota -Path $Path -ErrorAction SilentlyContinue
    if (-not $ExistingQuota -and $PSCmdlet.ShouldProcess($Path,'Apply course quota')) { New-FsrmQuota -Path $Path -Template $Template | Out-Null }
    elseif ($ExistingQuota -and $ExistingQuota.Template -ne $Template) { Write-Az802Status WARN 'A quota already exists on the course path with a different template; it was not overwritten.' }
    Get-FsrmQuota -Path $Path -ErrorAction SilentlyContinue
}
