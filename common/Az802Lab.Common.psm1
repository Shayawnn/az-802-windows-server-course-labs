Set-StrictMode -Version Latest

function Write-Az802Header {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Title)
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor DarkGray
    Write-Host ('AZ-802 LAB | {0}' -f $Title) -ForegroundColor Cyan
    Write-Host ('Host       : {0}' -f $env:COMPUTERNAME)
    Write-Host ('PowerShell : {0}' -f $PSVersionTable.PSVersion)
    Write-Host ('Time       : {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    Write-Host ('=' * 72) -ForegroundColor DarkGray
}

function Write-Az802Step {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][int]$Number,[Parameter(Mandatory=$true)][string]$Text)
    Write-Host ''
    Write-Host ('Step {0} | {1}' -f $Number,$Text) -ForegroundColor Cyan
}

function Write-Az802Status {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateSet('OK','INFO','WARN','SKIP','CREATE','CHANGE','FAIL')][string]$Kind,
        [Parameter(Mandatory=$true)][string]$Message
    )
    $Color = switch ($Kind) {
        'OK' {'Green'} 'INFO' {'Gray'} 'WARN' {'Yellow'} 'SKIP' {'DarkYellow'}
        'CREATE' {'Green'} 'CHANGE' {'Yellow'} 'FAIL' {'Red'} default {'White'}
    }
    Write-Host ('[{0}] {1}' -f $Kind,$Message) -ForegroundColor $Color
}

function Test-Az802Administrator {
    [CmdletBinding()]
    param()
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Az802Administrator {
    [CmdletBinding()]
    param()
    if (-not (Test-Az802Administrator)) { throw 'Open Windows PowerShell as Administrator and run the script again.' }
}

function Get-Az802RepoRoot {
    [CmdletBinding()]
    param()
    return (Split-Path -Parent $PSScriptRoot)
}

function Import-Az802Config {
    [CmdletBinding()]
    param([string]$RepoRoot)
    if (-not $RepoRoot) { $RepoRoot = Get-Az802RepoRoot }
    $Local = Join-Path $RepoRoot 'config\LabConfig.psd1'
    $Example = Join-Path $RepoRoot 'config\LabConfig.example.psd1'
    $Path = if (Test-Path -LiteralPath $Local) { $Local } else { $Example }
    if (-not (Test-Path -LiteralPath $Path)) { throw 'Lab configuration file is missing.' }
    return Import-PowerShellDataFile -LiteralPath $Path
}

function Get-Az802PrimaryAdapter {
    [CmdletBinding()]
    param()
    $Candidates = Get-NetIPConfiguration | Where-Object {
        $_.NetAdapter.Status -eq 'Up' -and $_.IPv4Address -and $_.IPv4DefaultGateway
    }
    if (-not $Candidates) {
        $Candidates = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.IPv4Address }
    }
    return $Candidates | Sort-Object { if ($_.NetIPv4Interface) { $_.NetIPv4Interface.InterfaceMetric } else { [int]::MaxValue } } | Select-Object -First 1
}

function Get-Az802PrimaryIPv4 {
    [CmdletBinding()]
    param()
    $Config = Get-Az802PrimaryAdapter
    if ($Config -and $Config.IPv4Address) { return $Config.IPv4Address.IPAddress | Select-Object -First 1 }
    return $null
}

function Get-Az802DomainContext {
    [CmdletBinding()]
    param()
    $ComputerSystem = Get-CimInstance Win32_ComputerSystem
    $Result = [ordered]@{
        PartOfDomain = [bool]$ComputerSystem.PartOfDomain
        DnsRoot = $null
        NetBIOSName = $null
        DistinguishedName = $null
    }
    if ($ComputerSystem.PartOfDomain) {
        $Result.DnsRoot = [string]$ComputerSystem.Domain
        if (Get-Command Get-ADDomain -ErrorAction SilentlyContinue) {
            try {
                $Domain = Get-ADDomain -ErrorAction Stop
                $Result.DnsRoot = $Domain.DNSRoot
                $Result.NetBIOSName = $Domain.NetBIOSName
                $Result.DistinguishedName = $Domain.DistinguishedName
            } catch { }
        }
    }
    return [pscustomobject]$Result
}

function Test-Az802IsDomainController {
    [CmdletBinding()]
    param()
    try {
        $Feature = Get-WindowsFeature AD-Domain-Services -ErrorAction Stop
        if (-not $Feature.Installed) { return $false }
        return [bool](Get-Service NTDS -ErrorAction SilentlyContinue)
    } catch { return $false }
}

function Get-Az802LocalGroupNameBySid {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Sid)
    $SecurityIdentifier = New-Object System.Security.Principal.SecurityIdentifier($Sid)
    $Account = $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value
    if ($Account -match '\\') { return $Account.Split('\\')[-1] }
    return $Account
}

function Get-Az802AccountNameBySid {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Sid)
    $SecurityIdentifier = New-Object System.Security.Principal.SecurityIdentifier($Sid)
    return $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value
}


function Invoke-Az802Native {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [int[]]$AllowedExitCodes = @(0),
        [switch]$WarnOnly
    )
    & $FilePath @ArgumentList
    $Code = $LASTEXITCODE
    if ($AllowedExitCodes -notcontains $Code) {
        $Message = '{0} exited with code {1}.' -f $FilePath,$Code
        if ($WarnOnly) { Write-Az802Status WARN $Message; return $Code }
        throw $Message
    }
    return $Code
}

function Test-Az802Command {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Assert-Az802Command {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name,[string]$Hint)
    if (-not (Test-Az802Command $Name)) {
        $Message = 'Required command is unavailable: {0}.' -f $Name
        if ($Hint) { $Message += ' ' + $Hint }
        throw $Message
    }
}

function Initialize-Az802Directory {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Az802Status CREATE ('Created directory {0}' -f $Path)
    } else {
        Write-Az802Status OK ('Directory exists: {0}' -f $Path)
    }
}

function Test-Az802TcpPort {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$ComputerName,[Parameter(Mandatory=$true)][int]$Port)
    try { return [bool](Test-NetConnection -ComputerName $ComputerName -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue) }
    catch { return $false }
}

function ConvertTo-Az802BaseDN {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$DnsName)
    return (($DnsName -split '\.') | ForEach-Object { 'DC={0}' -f $_ }) -join ','
}

function Test-Az802CourseName {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)
    return $Name -match '^(AZ802[-_]|az802[-_])'
}

function Test-Az802IPv4Address {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Address)
    $Ip = $null
    if (-not [System.Net.IPAddress]::TryParse($Address,[ref]$Ip)) { return $false }
    return $Ip.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
}

function Convert-Az802IPv4ToUInt32 {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Address)
    $Bytes = ([System.Net.IPAddress]::Parse($Address)).GetAddressBytes()
    [Array]::Reverse($Bytes)
    return [BitConverter]::ToUInt32($Bytes,0)
}

function Test-Az802AddressInPrefix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Address,
        [Parameter(Mandatory=$true)][string]$NetworkAddress,
        [Parameter(Mandatory=$true)][ValidateRange(0,32)][int]$PrefixLength
    )
    if (-not (Test-Az802IPv4Address $Address) -or -not (Test-Az802IPv4Address $NetworkAddress)) { return $false }
    $Mask = if ($PrefixLength -eq 0) { [uint32]0 } else { [uint32]::MaxValue -shl (32-$PrefixLength) }
    return ((Convert-Az802IPv4ToUInt32 $Address) -band $Mask) -eq ((Convert-Az802IPv4ToUInt32 $NetworkAddress) -band $Mask)
}

Export-ModuleMember -Function Write-Az802Header,Write-Az802Step,Write-Az802Status,Test-Az802Administrator,Assert-Az802Administrator,Get-Az802RepoRoot,Import-Az802Config,Get-Az802PrimaryAdapter,Get-Az802PrimaryIPv4,Get-Az802DomainContext,Test-Az802IsDomainController,Get-Az802LocalGroupNameBySid,Get-Az802AccountNameBySid,Invoke-Az802Native,Test-Az802Command,Assert-Az802Command,Initialize-Az802Directory,Test-Az802TcpPort,ConvertTo-Az802BaseDN,Test-Az802CourseName,Test-Az802IPv4Address,Test-Az802AddressInPrefix
