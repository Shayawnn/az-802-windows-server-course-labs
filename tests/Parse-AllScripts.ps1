#Requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$RepoRoot=Split-Path -Parent $PSScriptRoot
$Files=Get-ChildItem $RepoRoot -Recurse -File | Where-Object Extension -in '.ps1','.psm1','.psd1'
$Failures=@()
foreach ($File in $Files) {
    $Tokens=$null; $Errors=$null
    [System.Management.Automation.Language.Parser]::ParseFile($File.FullName,[ref]$Tokens,[ref]$Errors) | Out-Null
    if ($Errors) {
        foreach ($Error in $Errors) { $Failures += [pscustomobject]@{File=$File.FullName;Line=$Error.Extent.StartLineNumber;Message=$Error.Message} }
    }
}
if ($Failures.Count -gt 0) { $Failures | Format-Table -AutoSize; throw ('PowerShell parser found {0} error(s).' -f $Failures.Count) }
Write-Host ('[OK] Parsed {0} PowerShell/data files without syntax errors.' -f $Files.Count) -ForegroundColor Green
