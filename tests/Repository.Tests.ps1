$RepoRoot = Split-Path -Parent $PSScriptRoot

Describe 'AZ-802 repository structure' {
    It 'has the environment-preparation runner and one runner for each course module' {
        Test-Path -LiteralPath (Join-Path $RepoRoot '00-environment-preparation\Run-EnvironmentPreparation.ps1') | Should -BeTrue
        foreach ($Dir in @(
            '01-initial-configuration',
            '02-active-directory',
            '03-remote-administration',
            '04-hyperv',
            '05-network-services',
            '06-storage',
            '07-security-monitoring-ir'
        )) {
            Test-Path -LiteralPath (Join-Path $RepoRoot ($Dir + '\Run-Module.ps1')) | Should -BeTrue
        }
    }

    It 'has the shared module and configuration example' {
        Test-Path -LiteralPath (Join-Path $RepoRoot 'common\Az802Lab.Common.psm1') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $RepoRoot 'config\LabConfig.example.psd1') | Should -BeTrue
    }

    It 'contains no runner references to missing local scripts' {
        $Missing = @()
        $Runners = @(
            Get-Item -LiteralPath (Join-Path $RepoRoot '00-environment-preparation\Run-EnvironmentPreparation.ps1')
            Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter 'Run-Module.ps1'
        )
        foreach ($Runner in $Runners) {
            $Text = Get-Content -LiteralPath $Runner.FullName -Raw
            [regex]::Matches($Text, "'([^']+\.ps1)'") | ForEach-Object {
                $RelativeName = $_.Groups[1].Value
                $Candidate = Join-Path $Runner.DirectoryName $RelativeName
                if (-not (Test-Path -LiteralPath $Candidate -PathType Leaf)) {
                    $Missing += ('{0} -> {1}' -f $Runner.FullName,$RelativeName)
                }
            }
        }
        $Missing | Should -BeNullOrEmpty
    }

    It 'has no duplicate PowerShell filenames inside a module directory' {
        $Duplicates = @()
        Get-ChildItem -LiteralPath $RepoRoot -Directory | Where-Object Name -Match '^\d\d-' | ForEach-Object {
            $Seen = @{}
            Get-ChildItem -LiteralPath $_.FullName -File -Filter '*.ps1' | ForEach-Object {
                $Key = $_.Name.ToLowerInvariant()
                if ($Seen.ContainsKey($Key)) { $Duplicates += $_.FullName } else { $Seen[$Key] = $true }
            }
        }
        $Duplicates | Should -BeNullOrEmpty
    }
}
