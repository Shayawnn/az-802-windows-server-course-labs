#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 3 | WinRM and PowerShell remoting

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes

.CHANGES
Optionally enables local remoting. Remote commands only run when a separate peer is explicitly configured and reachable.

#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$EnableLocalRemoting,
    [string]$ComputerName,
    [PSCredential]$Credential
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 3 | WinRM and PowerShell remoting'
$Config = Import-Az802Config -RepoRoot $RepoRoot

# Step 1: Verify or enable local PowerShell remoting.
Write-Az802Step 1 'Verify local WinRM'
Get-Service WinRM
if ($EnableLocalRemoting -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,'Enable PowerShell remoting')) { Enable-PSRemoting -Force }
try { Test-WSMan localhost | Out-Host; Write-Az802Status OK 'Local WSMan endpoint responds.' } catch { Write-Az802Status WARN $_.Exception.Message }

# Step 2: Resolve an optional separate Windows peer.
Write-Az802Step 2 'Resolve optional remote Windows host'
if (-not $ComputerName) { $ComputerName = $Config.PeerWindowsHost }
if (-not $ComputerName) { Write-Az802Status SKIP 'No peer Windows Server is configured. Local WinRM verification is complete.'; return }
if ($ComputerName -ieq $env:COMPUTERNAME -or $ComputerName -in @('localhost','127.0.0.1')) { Write-Az802Status SKIP 'Remote demonstration requires a separate machine; the supplied target resolves to the current host.'; return }

# Step 3: Test TCP and WSMan before opening a session.
Write-Az802Step 3 'Test the peer before remoting'
if (-not (Test-Az802TcpPort -ComputerName $ComputerName -Port 5985)) { Write-Az802Status SKIP ('TCP/5985 is not reachable on {0}.' -f $ComputerName); return }
$WsManSucceeded = $false
try {
    if ($Credential) { Test-WSMan -ComputerName $ComputerName -Credential $Credential -Authentication Default -ErrorAction Stop | Out-Host }
    else { Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Host }
    $WsManSucceeded = $true
} catch {
    if (-not $Credential) {
        Write-Az802Status INFO 'The current logon token could not authenticate to WSMan. An explicit credential can be tried.'
        $Credential = Get-Credential -Message ('Credential for {0}' -f $ComputerName)
        try { Test-WSMan -ComputerName $ComputerName -Credential $Credential -Authentication Default -ErrorAction Stop | Out-Host; $WsManSucceeded = $true } catch { Write-Az802Status SKIP ('WSMan authentication failed on {0}: {1}' -f $ComputerName,$_.Exception.Message); return }
    } else {
        Write-Az802Status SKIP ('WSMan did not authenticate on {0}: {1}' -f $ComputerName,$_.Exception.Message)
        return
    }
}
if (-not $WsManSucceeded) { return }
if (-not $Credential) { $Credential = Get-Credential -Message ('Credential for the persistent session to {0}' -f $ComputerName) }

# Step 4: Create one persistent session, run a visible command and close it.
Write-Az802Step 4 'Use a persistent PSSession'
$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
try {
    Invoke-Command -Session $Session -ScriptBlock { hostname; Get-Date; Get-Service WinRM | Select-Object Name,Status,StartType }
    if ($PSCmdlet.ShouldProcess(('C:\AZ802\Remote on {0}' -f $ComputerName),'Create the course remote-work directory')) {
        Invoke-Command -Session $Session -ScriptBlock { New-Item -ItemType Directory -Path 'C:\AZ802\Remote' -Force | Out-Null }
    }
    Write-Az802Status OK ('Remote session to {0} succeeded.' -f $ComputerName)
} finally { Remove-PSSession $Session -ErrorAction SilentlyContinue }
