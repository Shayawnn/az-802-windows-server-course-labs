#Requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$RepoRoot=Split-Path -Parent $PSScriptRoot
$Implementation=Get-ChildItem $RepoRoot -Recurse -File | Where-Object { $_.Extension -in '.ps1','.psm1','.psd1','.sh' -and $_.FullName -notmatch '\\tests\\Repository-Hygiene\.ps1$' }
$Problems=@()
$Rules=@(
    @{Name='Historical srv.world identity';Pattern='srv\.world'},
    @{Name='Historical RX host identity';Pattern='\bRX-\d+\b'},
    @{Name='Contoso executable identity';Pattern='contoso\.local'},
    @{Name='Angle-bracket placeholder';Pattern='<[A-Za-z][^>]{1,40}>'},
    @{Name='Known classroom plaintext password';Pattern='P@ssw0rd|DemoP@ssw0rd|UserP@ssw0rd'},
    @{Name='ConvertTo-SecureString AsPlainText';Pattern='ConvertTo-SecureString[^\r\n]*-AsPlainText'},
    @{Name='Hardcoded interface index';Pattern='-InterfaceIndex\s+(?:3|11)\b'},
    @{Name='Hardcoded disk one assignment';Pattern='\$DiskNumber\s*=\s*1\b'},
    @{Name='Pedagogy/meta narration';Pattern='student sees|learner should|as discussed|between you and me|the point is to show|this slide|these slides|ChatGPT|OpenAI'},
    @{Name='Corrupted training prose';Pattern='not a special value|OpenSecure Shell|examples, example values|The The\b'}
)
foreach ($File in $Implementation) {
    $Text=Get-Content -LiteralPath $File.FullName -Raw
    foreach ($Rule in $Rules) {
        if ($Text -match $Rule.Pattern) { $Problems += [pscustomobject]@{File=$File.FullName;Rule=$Rule.Name;Match=$Matches[0]} }
    }
}
if ($Problems.Count -gt 0) { $Problems | Format-Table -AutoSize; throw ('Repository hygiene found {0} problem(s).' -f $Problems.Count) }
Write-Host ('[OK] Repository hygiene passed for {0} implementation files.' -f $Implementation.Count) -ForegroundColor Green
