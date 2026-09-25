#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 2 | Optional domain join for a separate Windows machine

.RUN ON
Domain controller or administration server. The join target must be a separate Windows machine reachable through WinRM.

.SAFE TO RERUN
Yes. The current machine, localhost and an already joined target are not treated as disposable join targets.

.CHANGES
Optionally configures DNS and joins an explicitly selected remote Windows machine to the domain. Remote-administration and domain-join credentials are separate because a workgroup machine commonly needs a local administrator for WinRM.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ComputerName,
    [string]$DomainName,
    [string]$DomainDnsServer,
    [PSCredential]$RemoteCredential,
    [PSCredential]$DomainJoinCredential
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 2 | Optional domain join'
$Config = Import-Az802Config -RepoRoot $RepoRoot
$Context = Get-Az802DomainContext

# Step 1: Resolve a real separate Windows target.
Write-Az802Step 1 'Resolve optional client or peer host'
if (-not $ComputerName) { $ComputerName = $Config.WindowsClient }
if (-not $ComputerName) { $ComputerName = $Config.PeerWindowsHost }
if (-not $ComputerName) { Write-Az802Status SKIP 'No optional Windows client/server is configured. Domain join requires another Windows machine.'; return }
if ($ComputerName -ieq $env:COMPUTERNAME -or $ComputerName -in @('localhost','127.0.0.1','::1','.')) { Write-Az802Status SKIP 'Domain-join demonstration requires a separate Windows machine; the supplied target is the current host.'; return }

# Step 2: Resolve the target domain and DNS server explicitly.
Write-Az802Step 2 'Validate domain-join inputs'
if (-not $DomainName -and $Context.DnsRoot) { $DomainName = $Context.DnsRoot }
if (-not $DomainName) { throw 'Supply -DomainName or run this script from a domain-joined administration server.' }
if (-not $DomainDnsServer) {
    if (Test-Az802IsDomainController) { $DomainDnsServer = Get-Az802PrimaryIPv4 }
}
if (-not $DomainDnsServer -or -not (Test-Az802IPv4Address $DomainDnsServer)) { throw 'Supply -DomainDnsServer as the real IPv4 address of the AD DNS server.' }
if (-not (Test-Az802TcpPort -ComputerName $ComputerName -Port 5985)) { Write-Az802Status SKIP ('TCP/5985 is not reachable on {0}. Prepare WinRM on that machine first.' -f $ComputerName); return }
if (-not $RemoteCredential) { $RemoteCredential = Get-Credential -Message ('Local/domain administrator credential that can open a WinRM session to {0}' -f $ComputerName) }
if (-not $DomainJoinCredential) { $DomainJoinCredential = Get-Credential -Message ('Credential permitted to join computers to {0}' -f $DomainName) }

# Step 3: Inspect the remote machine before changing DNS or membership.
Write-Az802Step 3 'Inspect the remote Windows machine'
try {
    $RemoteState = Invoke-Command -ComputerName $ComputerName -Credential $RemoteCredential -ErrorAction Stop -ScriptBlock {
        $Cs = Get-CimInstance Win32_ComputerSystem
        [pscustomobject]@{ ComputerName=$env:COMPUTERNAME; PartOfDomain=[bool]$Cs.PartOfDomain; Domain=[string]$Cs.Domain }
    }
} catch {
    Write-Az802Status SKIP ('WinRM authentication/session setup failed for {0}: {1}' -f $ComputerName,$_.Exception.Message)
    Write-Az802Status INFO 'A workgroup target may require TrustedHosts/HTTPS or running the join script locally on that target.'
    return
}
$RemoteState | Format-List
if ($RemoteState.PartOfDomain) {
    if ($RemoteState.Domain -ieq $DomainName) { Write-Az802Status OK ('{0} already belongs to {1}.' -f $ComputerName,$DomainName); return }
    throw ('{0} already belongs to domain {1}; refusing to move it automatically.' -f $ComputerName,$RemoteState.Domain)
}

# Step 4: Configure AD DNS and join the separate machine.
Write-Az802Step 4 'Configure DNS and join the remote machine'
if ($PSCmdlet.ShouldProcess($ComputerName,('Configure DNS and join {0}' -f $DomainName))) {
    Invoke-Command -ComputerName $ComputerName -Credential $RemoteCredential -ArgumentList $DomainDnsServer,$DomainName,$DomainJoinCredential -ErrorAction Stop -ScriptBlock {
        param($DnsServer,$Domain,[System.Management.Automation.PSCredential]$JoinCredential)
        $Adapter = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.IPv4Address -and $_.IPv4DefaultGateway } | Select-Object -First 1
        if (-not $Adapter) { throw 'No active IPv4 adapter with a default gateway was found.' }
        Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -ServerAddresses $DnsServer
        Add-Computer -DomainName $Domain -Credential $JoinCredential -ErrorAction Stop
    }
    Write-Az802Status WARN ('Domain join was requested on {0}. Restart that machine before relying on domain membership.' -f $ComputerName)
}
