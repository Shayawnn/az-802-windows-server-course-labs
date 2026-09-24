#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 5 | DHCP bad-DNS scenario

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Build preserves an existing clean baseline unless -ResetBaseline is explicitly supplied. Repair never guesses the clean DNS server.

.CHANGES
Runs a reversible DHCP option-006 failure scenario and stores its visible repair baseline under C:\AZ802\State.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Build','Break','Observe','Repair','Verify')][string]$Phase = 'Observe',
    [string]$ScopeId,
    [string[]]$GoodDnsServer,
    [string[]]$BadDnsServer,
    [switch]$ResetBaseline
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 5 | DHCP bad-DNS scenario'
if (-not (Test-Az802Command Get-DhcpServerv4Scope)) { Write-Az802Status SKIP 'DHCP Server management tools are not available.'; return }
Import-Module DhcpServer
$StateDir = 'C:\AZ802\State'
$StateFile = Join-Path $StateDir 'dhcp-bad-dns-baseline.json'

# Step 1: Resolve an explicit existing scope.
Write-Az802Step 1 'Resolve the DHCP scope'
if (-not $ScopeId) {
    $Scopes = @(Get-DhcpServerv4Scope -ErrorAction SilentlyContinue)
    if ($Scopes.Count -eq 1) { $ScopeId = [string]$Scopes[0].ScopeId }
    else { Write-Az802Status SKIP 'Supply -ScopeId when zero or multiple scopes exist.'; return }
}
$Scope = Get-DhcpServerv4Scope -ScopeId $ScopeId -ErrorAction Stop
$Scope | Select-Object ScopeId,Name,State,StartRange,EndRange
foreach ($Address in @($GoodDnsServer) + @($BadDnsServer)) { if ($Address -and -not (Test-Az802IPv4Address $Address)) { throw ('Invalid IPv4 DNS server address: {0}' -f $Address) } }

# Step 2: Execute the reversible option-006 scenario.
Write-Az802Step 2 ('Scenario phase: {0}' -f $Phase)
switch ($Phase) {
    'Build' {
        if (-not (Test-Path -LiteralPath $StateDir) -and $PSCmdlet.ShouldProcess($StateDir,'Create the scenario state directory')) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
        if ($ResetBaseline -and (Test-Path -LiteralPath $StateFile) -and $PSCmdlet.ShouldProcess($StateFile,'Discard the saved DHCP scenario baseline')) { Remove-Item -LiteralPath $StateFile -Force }
        if (Test-Path -LiteralPath $StateFile) {
            $Baseline = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
            if ([string]$Baseline.ScopeId -ne [string]$ScopeId) { throw ('A baseline already exists for scope {0}. Use -ResetBaseline deliberately before building a different scope scenario.' -f $Baseline.ScopeId) }
            Write-Az802Status OK ('Existing clean baseline preserved: DNS {0}' -f (@($Baseline.GoodDnsServer) -join ', '))
            return
        }
        $Current = Get-DhcpServerv4OptionValue -ScopeId $ScopeId
        $DnsOpt = $Current | Where-Object OptionId -eq 6
        if ((-not $DnsOpt -or -not $DnsOpt.Value) -and -not $GoodDnsServer) { throw 'The scope has no DNS option. Supply -GoodDnsServer before running Build.' }
        if (-not $GoodDnsServer) { $GoodDnsServer = @($DnsOpt.Value | ForEach-Object { [string]$_ }) }
        if ($PSCmdlet.ShouldProcess($StateFile,'Save the DHCP DNS repair baseline')) {
            @{ScopeId=[string]$ScopeId;GoodDnsServer=@($GoodDnsServer);Created=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath $StateFile
        }
        if (Test-Path -LiteralPath $StateFile) { Write-Az802Status OK ('Saved clean DNS option: {0}' -f ($GoodDnsServer -join ', ')) }
        else { Write-Az802Status INFO 'Repair baseline was not written.' }
    }
    'Break' {
        if (-not $BadDnsServer -or $BadDnsServer.Count -eq 0) { throw 'Supply -BadDnsServer.' }
        if (-not (Test-Path -LiteralPath $StateFile)) { throw 'Run -Phase Build first.' }
        if ($PSCmdlet.ShouldProcess($ScopeId,('Set bad DNS option {0}' -f ($BadDnsServer -join ', ')))) { Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsServer $BadDnsServer }
    }
    'Observe' {
        Get-DhcpServerv4OptionValue -ScopeId $ScopeId
        Get-DhcpServerv4Lease -ScopeId $ScopeId -ErrorAction SilentlyContinue
    }
    'Repair' {
        if (-not (Test-Path -LiteralPath $StateFile)) { throw 'Repair baseline is missing; refusing to guess the clean DNS server.' }
        $Baseline = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
        $SavedDns = @($Baseline.GoodDnsServer)
        if ($PSCmdlet.ShouldProcess($ScopeId,('Restore DNS option {0}' -f ($SavedDns -join ', ')))) { Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsServer $SavedDns }
    }
    'Verify' {
        $Options = Get-DhcpServerv4OptionValue -ScopeId $ScopeId
        $Options
        if (Test-Path -LiteralPath $StateFile) {
            $Baseline = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
            $Expected = @($Baseline.GoodDnsServer | ForEach-Object { [string]$_ } | Sort-Object)
            $DnsOpt = $Options | Where-Object OptionId -eq 6
            $Actual = @($DnsOpt.Value | ForEach-Object { [string]$_ } | Sort-Object)
            if (($Expected -join '|') -eq ($Actual -join '|')) {
                Write-Az802Status OK 'DHCP DNS option matches the saved baseline.'
                if ($PSCmdlet.ShouldProcess($StateFile,'Remove the completed scenario baseline')) { Remove-Item -LiteralPath $StateFile -Force }
            } else {
                Write-Az802Status WARN ('DHCP DNS option differs from the baseline. Expected: {0} | Actual: {1}' -f ($Expected -join ', '),($Actual -join ', '))
            }
        }
    }
}
