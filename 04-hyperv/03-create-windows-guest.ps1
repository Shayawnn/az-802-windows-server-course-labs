#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 4 | Create a Windows Server guest

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Creates or reuses one AZ802-prefixed Windows VM only when -Create is supplied. Existing VM settings are inspected rather than silently overwritten. ISO/firmware changes are refused while the VM runs.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VMName = 'AZ802-WIN01',
    [string]$SwitchName = 'AZ802-LabNAT',
    [string]$IsoPath,
    [uint64]$VhdSize = 60GB,
    [uint64]$StartupMemory = 4GB,
    [uint64]$MaximumMemory = 6GB,
    [ValidateRange(1,64)][int]$ProcessorCount = 2,
    [switch]$Create,
    [switch]$Start
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 4 | Create a Windows Server guest'
$Config = Import-Az802Config -RepoRoot $RepoRoot
if (-not $IsoPath) { $IsoPath = $Config.WindowsServerIso }

# Step 1: Validate explicit media and switch prerequisites.
Write-Az802Step 1 'Validate VM prerequisites'
if (-not $Create) { Write-Az802Status INFO 'Use -Create with a valid Windows Server ISO path to create the guest.'; return }
if (-not $IsoPath -or -not (Test-Path -LiteralPath $IsoPath)) { throw 'Windows Server ISO path is missing or invalid. Supply -IsoPath or set WindowsServerIso in LabConfig.psd1.' }
if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) { throw ('Virtual switch not found: {0}' -f $SwitchName) }
if (-not (Test-Az802CourseName $VMName)) { throw 'VMName must be AZ802-prefixed.' }

# Step 2: Create or verify the virtual machine.
Write-Az802Step 2 'Create or verify the Windows guest'
$VMRoot = Join-Path $Config.LabRoot 'VMs'
Initialize-Az802Directory -Path $VMRoot
$VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if (-not $VM -and $PSCmdlet.ShouldProcess($VMName,'Create Windows guest')) {
    $VMPath = Join-Path $VMRoot $VMName
    $VhdPath = Join-Path $VMPath ($VMName + '.vhdx')
    $VM = New-VM -Name $VMName -MemoryStartupBytes $StartupMemory -Generation 2 -NewVHDPath $VhdPath -NewVHDSizeBytes $VhdSize -Path $VMPath -SwitchName $SwitchName
    Set-VMProcessor -VMName $VMName -Count $ProcessorCount
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes $StartupMemory -MaximumBytes $MaximumMemory
}
$VM = Get-VM -Name $VMName
if ($VM.Generation -ne 2) { throw ('Existing VM {0} is Generation {1}; this lab expects Generation 2.' -f $VMName,$VM.Generation) }
$Adapter = Get-VMNetworkAdapter -VMName $VMName | Select-Object -First 1
if ($Adapter -and $Adapter.SwitchName -ne $SwitchName) { Write-Az802Status WARN ('Existing VM is connected to switch {0}; requested switch is {1}. No network attachment was changed automatically.' -f $Adapter.SwitchName,$SwitchName) }
if ($VM.ProcessorCount -ne $ProcessorCount) { Write-Az802Status INFO ('Existing VM has {0} vCPU; requested value is {1}. Existing configuration was preserved.' -f $VM.ProcessorCount,$ProcessorCount) }

# Step 3: Attach the ISO only while the VM is off.
Write-Az802Step 3 'Attach Windows installation media'
if ($VM.State -ne 'Off') { Write-Az802Status SKIP 'The VM is running. ISO/firmware changes are skipped until the VM is off.' }
else {
    $Dvd = Get-VMDvdDrive -VMName $VMName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $Dvd -and $PSCmdlet.ShouldProcess($VMName,'Add DVD drive')) { Add-VMDvdDrive -VMName $VMName -Path $IsoPath | Out-Null }
    else { if ($Dvd.Path -ne $IsoPath -and $PSCmdlet.ShouldProcess($VMName,'Change DVD ISO')) { Set-VMDvdDrive -VMName $VMName -Path $IsoPath } }
    $Dvd = Get-VMDvdDrive -VMName $VMName | Select-Object -First 1
    if ($Dvd -and $PSCmdlet.ShouldProcess($VMName,'Set DVD as first boot device')) { Set-VMFirmware -VMName $VMName -FirstBootDevice $Dvd }
}

# Step 4: Start only when explicitly requested.
Write-Az802Step 4 'Optional start'
if ($Start) {
    if ($VM.State -eq 'Off' -and $PSCmdlet.ShouldProcess($VMName,'Start VM')) { Start-VM -Name $VMName | Out-Null }
    else { Write-Az802Status INFO ('VM state is {0}; no start action required.' -f $VM.State) }
}
Get-VM -Name $VMName | Select-Object Name,State,Generation,ProcessorCount,MemoryStartup,Notes
Get-VMNetworkAdapter -VMName $VMName
