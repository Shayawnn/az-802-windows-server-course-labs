#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | Create a Linux guest

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Creates or reuses one AZ802-prefixed Linux VM only when -Create is supplied. Existing VM settings are inspected rather than silently overwritten.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VMName = 'AZ802-LINUX01',
    [string]$SwitchName = 'AZ802-LabNAT',
    [string]$IsoPath,
    [uint64]$VhdSize = 25GB,
    [uint64]$StartupMemory = 2GB,
    [ValidateRange(1,64)][int]$ProcessorCount = 2,
    [switch]$Create,
    [switch]$Start
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | Create a Linux guest'
$Config = Import-Az802Config -RepoRoot $RepoRoot
if (-not $IsoPath) { $IsoPath = $Config.LinuxIso }

# Step 1: Validate media and switch prerequisites.
Write-Az802Step 1 'Validate Linux guest prerequisites'
if (-not $Create) { Write-Az802Status INFO 'Use -Create with a valid Linux ISO path to create the guest.'; return }
if (-not $IsoPath -or -not (Test-Path -LiteralPath $IsoPath)) { throw 'Linux ISO path is missing or invalid. Supply -IsoPath or set LinuxIso in LabConfig.psd1.' }
if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) { throw ('Virtual switch not found: {0}' -f $SwitchName) }
if (-not (Test-Az802CourseName $VMName)) { throw 'VMName must be AZ802-prefixed.' }

# Step 2: Create or verify the Linux VM.
Write-Az802Step 2 'Create or verify the Linux guest'
$VMRoot = Join-Path $Config.LabRoot 'VMs'
Initialize-Az802Directory -Path $VMRoot
$VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if (-not $VM -and $PSCmdlet.ShouldProcess($VMName,'Create Linux guest')) {
    $VMPath = Join-Path $VMRoot $VMName
    $VhdPath = Join-Path $VMPath ($VMName + '.vhdx')
    $VM = New-VM -Name $VMName -MemoryStartupBytes $StartupMemory -Generation 2 -NewVHDPath $VhdPath -NewVHDSizeBytes $VhdSize -Path $VMPath -SwitchName $SwitchName
    Set-VMProcessor -VMName $VMName -Count $ProcessorCount
    Set-VMFirmware -VMName $VMName -EnableSecureBoot Off
}
$VM = Get-VM -Name $VMName
if ($VM.Generation -ne 2) { throw ('Existing VM {0} is Generation {1}; this lab expects Generation 2.' -f $VMName,$VM.Generation) }
$Adapter = Get-VMNetworkAdapter -VMName $VMName | Select-Object -First 1
if ($Adapter -and $Adapter.SwitchName -ne $SwitchName) { Write-Az802Status WARN ('Existing VM is connected to switch {0}; requested switch is {1}. No network attachment was changed automatically.' -f $Adapter.SwitchName,$SwitchName) }
if ($VM.ProcessorCount -ne $ProcessorCount) { Write-Az802Status INFO ('Existing VM has {0} vCPU; requested value is {1}. Existing configuration was preserved.' -f $VM.ProcessorCount,$ProcessorCount) }

# Step 3: Attach media only while the VM is off.
Write-Az802Step 3 'Attach Linux installation media'
$VM = Get-VM -Name $VMName
if ($VM.State -ne 'Off') { Write-Az802Status SKIP 'The VM is running. ISO changes are skipped until it is off.' }
else {
    $Dvd = Get-VMDvdDrive -VMName $VMName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $Dvd -and $PSCmdlet.ShouldProcess($VMName,'Add Linux ISO')) { Add-VMDvdDrive -VMName $VMName -Path $IsoPath | Out-Null }
    elseif ($Dvd.Path -ne $IsoPath -and $PSCmdlet.ShouldProcess($VMName,'Change Linux ISO')) { Set-VMDvdDrive -VMName $VMName -Path $IsoPath }
    $Dvd = Get-VMDvdDrive -VMName $VMName | Select-Object -First 1
    if ($Dvd -and $PSCmdlet.ShouldProcess($VMName,'Set DVD first boot')) { Set-VMFirmware -VMName $VMName -FirstBootDevice $Dvd }
}
if ($Start -and (Get-VM -Name $VMName).State -eq 'Off' -and $PSCmdlet.ShouldProcess($VMName,'Start VM')) { Start-VM -Name $VMName | Out-Null }
Get-VM -Name $VMName | Select-Object Name,State,Generation,ProcessorCount
Get-VMNetworkAdapter -VMName $VMName
