#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Module 6 | File damage and recovery scenario

.RUN ON
Current Windows Server

.SAFE TO RERUN
Yes. Build never overwrites an existing repair baseline. -ResetLab is required to discard an old course scenario.

.CHANGES
Operates only under C:\AZ802\RecoveryLab and uses a visible backup copy plus hash baseline for verification.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Build','Damage','Observe','Recover','Verify')][string]$Phase = 'Observe',
    [switch]$ResetLab
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') -Force
Write-Az802Header 'Module 6 | File damage and recovery scenario'
$Root = 'C:\AZ802\RecoveryLab'
$Data = Join-Path $Root 'Data'
$Backup = Join-Path $Root 'Backup'
$StateDir = 'C:\AZ802\State'
$State = Join-Path $StateDir 'file-recovery-baseline.json'

# Step 1: Execute the requested reversible file-recovery phase.
Write-Az802Step 1 ('Scenario phase: {0}' -f $Phase)
switch ($Phase) {
    'Build' {
        if (-not (Test-Path -LiteralPath $StateDir) -and $PSCmdlet.ShouldProcess($StateDir,'Create the scenario state directory')) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
        if ($ResetLab) {
            if ((Test-Path -LiteralPath $Root) -and $PSCmdlet.ShouldProcess($Root,'Reset the AZ802 recovery lab data')) { Remove-Item -LiteralPath $Root -Recurse -Force }
            if ((Test-Path -LiteralPath $State) -and $PSCmdlet.ShouldProcess($State,'Remove the AZ802 recovery baseline')) { Remove-Item -LiteralPath $State -Force }
        }
        if (Test-Path -LiteralPath $State) {
            if (-not (Test-Path -LiteralPath $Backup)) { throw 'A hash baseline exists but its backup directory is missing. Use -ResetLab to rebuild the course scenario deliberately.' }
            Write-Az802Status OK 'Existing recovery baseline and backup are preserved. Use -ResetLab only when you intentionally want a fresh scenario.'
            return
        }
        if ((Test-Path -LiteralPath $Root) -and (Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue)) { throw 'Scenario files exist without a saved baseline. Rerun Build with -ResetLab to discard only the AZ802 course scenario and rebuild it cleanly.' }
        if ($PSCmdlet.ShouldProcess($Root,'Build clean course files, backup copy and hash baseline')) {
            Initialize-Az802Directory -Path $Data
            Initialize-Az802Directory -Path $Backup
            1..5 | ForEach-Object { 'Important course file {0}' -f $_ | Set-Content -LiteralPath (Join-Path $Data ('file{0}.txt' -f $_)) }
            Copy-Item (Join-Path $Data '*') $Backup -Recurse -Force
            $Hashes = Get-ChildItem -LiteralPath $Data -File | Get-FileHash | Select-Object Path,Hash
            $Hashes | ConvertTo-Json | Set-Content -LiteralPath $State
            Write-Az802Status OK 'Clean files, backup copy and hash baseline are ready.'
        }
    }
    'Damage' {
        if (-not (Test-Path -LiteralPath $State)) { throw 'Run -Phase Build first.' }
        $CleanFiles = @(Get-ChildItem -LiteralPath $Data -Filter '*.txt' -File -ErrorAction SilentlyContinue)
        $LockedFiles = @(Get-ChildItem -LiteralPath $Data -Filter '*.locked' -File -ErrorAction SilentlyContinue)
        if ($CleanFiles.Count -eq 0 -and $LockedFiles.Count -gt 0) { Write-Az802Status INFO 'The course files are already in the damaged state.'; return }
        if ($CleanFiles.Count -eq 0) { throw 'No clean course files were found to damage.' }
        if ($PSCmdlet.ShouldProcess($Data,'Modify and rename only the AZ802 recovery-lab files')) {
            foreach ($File in $CleanFiles) {
                Set-Content -LiteralPath $File.FullName -Value 'DAMAGED - AZ802 LAB ONLY'
                Rename-Item -LiteralPath $File.FullName -NewName ($File.BaseName + '.locked')
            }
            Write-Az802Status WARN 'Course files were deliberately modified and renamed.'
        }
    }
    'Observe' { Get-ChildItem -LiteralPath $Data -File -ErrorAction SilentlyContinue | Select-Object Name,Length,LastWriteTime }
    'Recover' {
        if (-not (Test-Path -LiteralPath $Backup)) { throw 'Backup directory is missing.' }
        if (-not (Test-Path -LiteralPath $State)) { throw 'Hash baseline is missing; refusing to claim this backup is the saved clean state.' }
        if ($PSCmdlet.ShouldProcess($Data,'Replace damaged course files with the saved lab backup')) {
            Initialize-Az802Directory -Path $Data
            Remove-Item (Join-Path $Data '*') -Recurse -Force -ErrorAction SilentlyContinue
            Copy-Item (Join-Path $Backup '*') $Data -Recurse -Force
            Write-Az802Status OK 'Course files were restored from the saved lab backup.'
        }
    }
    'Verify' {
        if (-not (Test-Path -LiteralPath $State)) { throw 'Hash baseline is missing.' }
        $Before = @(Get-Content -LiteralPath $State -Raw | ConvertFrom-Json)
        $After = @(Get-ChildItem -LiteralPath $Data -File | Get-FileHash | Select-Object Path,Hash)
        $Expected = @{}
        foreach ($H in $Before) { $Expected[[IO.Path]::GetFileName($H.Path)] = $H.Hash }
        $Mismatch = @()
        foreach ($H in $After) { $Name=[IO.Path]::GetFileName($H.Path); if (-not $Expected.ContainsKey($Name) -or $Expected[$Name] -ne $H.Hash) { $Mismatch += $Name } }
        if ($Mismatch.Count -eq 0 -and $After.Count -eq $Before.Count) { Write-Az802Status OK 'Recovered files match the saved hash baseline.' }
        else { Write-Az802Status WARN ('Recovery does not match the baseline. Mismatched or unexpected files: {0}' -f (($Mismatch | Sort-Object -Unique) -join ', ')) }
    }
}
