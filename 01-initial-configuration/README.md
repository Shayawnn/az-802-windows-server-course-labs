# Module 1 - Initial configuration

The default `Run-Module.ps1` path is conservative. Environment-specific, destructive or scenario scripts are run separately with explicit parameters.

## Files

- `Run-Module.ps1`
- `01-inventory-and-preflight.ps1`
- `02-local-accounts.ps1`
- `03-network-dns-time.ps1`
- `04-computer-name.ps1`
- `05-firewall-and-rdp.ps1`
- `06-supplemental-system-administration.ps1`

Use `Get-Help .\<script>.ps1 -Full` for parameter help when the script has parameters. Read the script header before running a changing action.
