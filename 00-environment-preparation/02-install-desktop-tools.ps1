#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Install optional desktop tools for a Windows Server Desktop Experience lab.

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Installed applications are detected before downloading or installing anything.

.CHANGES
Downloads and installs Google Chrome, Mozilla Firefox ESR and Visual Studio Code on Desktop Experience. Installer signatures are checked unless explicitly disabled.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$SkipSignatureCheck
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Environment preparation | Desktop tools'

if (-not (Test-Path "$env:WINDIR\explorer.exe")) {
    Write-Az802Status SKIP 'Server Core detected. GUI desktop tools are not installed.'
    return
}

$Downloads = Join-Path $env:TEMP 'AZ802-Downloads'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Test-Az802ApplicationPath {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string[]]$CandidatePath)
    foreach ($Path in $CandidatePath) {
        if ($Path -and (Test-Path -LiteralPath $Path)) { return $Path }
    }
    return $null
}

function Install-SignedPackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string[]]$InstalledPath,
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$FileName,
        [string[]]$Arguments = @()
    )

    $Existing = Test-Az802ApplicationPath -CandidatePath $InstalledPath
    if ($Existing) {
        $Version = (Get-Item -LiteralPath $Existing).VersionInfo.ProductVersion
        Write-Az802Status OK ('{0} is already installed{1}.' -f $Name, $(if ($Version) { ' (' + $Version + ')' } else { '' }))
        return
    }

    $Path = Join-Path $Downloads $FileName
    if ($PSCmdlet.ShouldProcess($Name,'Download, verify and install')) {
        Initialize-Az802Directory -Path $Downloads
        Write-Az802Status INFO ('Downloading {0} from its official distribution endpoint.' -f $Name)
        Invoke-WebRequest -Uri $Uri -OutFile $Path -UseBasicParsing

        if (-not $SkipSignatureCheck) {
            $Signature = Get-AuthenticodeSignature -FilePath $Path
            if ($Signature.Status -ne 'Valid') {
                Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
                throw ('{0} installer signature is not valid: {1}' -f $Name,$Signature.Status)
            }
        }

        if ($Path -like '*.msi') {
            $Process = Start-Process msiexec.exe -ArgumentList @('/i',('"{0}"' -f $Path),'/qn','/norestart') -Wait -NoNewWindow -PassThru
        } else {
            $Process = Start-Process $Path -ArgumentList $Arguments -Wait -PassThru
        }
        if ($Process.ExitCode -notin @(0,1641,3010)) { throw ('{0} installer exited with code {1}.' -f $Name,$Process.ExitCode) }
        if ($Process.ExitCode -in @(1641,3010)) { Write-Az802Status WARN ('{0} installed successfully and requested a restart.' -f $Name) }
        else { Write-Az802Status OK ('Installed {0}.' -f $Name) }
    }
}

# Step 1: Install or verify Google Chrome.
Write-Az802Step 1 'Install or verify Google Chrome'
Install-SignedPackage -Name 'Google Chrome' `
    -InstalledPath @((Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),(Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')) `
    -Uri 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' `
    -FileName 'chrome.msi'

# Step 2: Install or verify Mozilla Firefox ESR.
Write-Az802Step 2 'Install or verify Mozilla Firefox ESR'
Install-SignedPackage -Name 'Mozilla Firefox ESR' `
    -InstalledPath @((Join-Path $env:ProgramFiles 'Mozilla Firefox\firefox.exe'),(Join-Path ${env:ProgramFiles(x86)} 'Mozilla Firefox\firefox.exe')) `
    -Uri 'https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64&lang=en-US' `
    -FileName 'firefox.exe' `
    -Arguments @('-ms')

# Step 3: Install or verify Visual Studio Code.
Write-Az802Step 3 'Install or verify Visual Studio Code'
Install-SignedPackage -Name 'Visual Studio Code' `
    -InstalledPath @((Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe'),(Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe')) `
    -Uri 'https://update.code.visualstudio.com/latest/win32-x64/stable' `
    -FileName 'vscode.exe' `
    -Arguments @('/VERYSILENT','/NORESTART','/MERGETASKS=!runcode')
