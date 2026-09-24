# Environment preparation

This folder gets a fresh Windows Server ready for the rest of the labs. The normal run is read-only. Browsers, VS Code, Sysinternals and Ubuntu media are optional extras.

## What you will practice

- Check whether the server is suitable for the labs before changing it.
- Understand the difference between Server Core and Desktop Experience.
- Install optional classroom tools from their official sources.
- Keep installation media and machine-specific paths outside the scripts.

## Before you start

- Run Windows PowerShell 5.1 as Administrator.
- Start from the repository root so the shared module and config paths resolve normally.
- Internet access is only needed for optional downloads.

## Start here

From the repository root, run the module entry point first:

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1
```

The runner uses the safe/default path. A script that needs a real hostname, disk number, IP address, credential, destructive action or connectivity-changing acknowledgement is left for you to run explicitly.

If a command is unfamiliar, use PowerShell help before running it:

```powershell
Get-Help .\00-environment-preparation\<script-name>.ps1 -Full
```

## Script guide

| Script | What it is for | Important inputs |
| --- | --- | --- |
| `01-preflight.ps1` | Read OS, elevation, network, disk and virtualization readiness | None |
| `02-install-desktop-tools.ps1` | Install optional browser/editor tools on Desktop Experience | `-SkipSignatureCheck` |
| `03-install-sysinternals.ps1` | Download and unpack the Sysinternals Suite | `-Refresh` |
| `04-download-lab-media.ps1` | Download and verify Ubuntu media; validate a supplied Windows Server ISO | `-DownloadUbuntu` |
| `Run-EnvironmentPreparation.ps1` | Run the safe preparation path and opt into extra setup | `-InstallDesktopTools`, `-IncludeSysinternals`, `-DownloadUbuntuIso` |

## Examples

```powershell
# Read-only preflight
.\00-environment-preparation\Run-EnvironmentPreparation.ps1

# Add desktop tools on Desktop Experience
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -InstallDesktopTools

# Add Sysinternals as well
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -InstallDesktopTools -IncludeSysinternals

# Download and verify Ubuntu Server LTS media
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -DownloadUbuntuIso
```

## What to pay attention to

- A `$null` value in `LabConfig.psd1` means "this optional thing is not configured." It is not an error.
- Windows Server media is intentionally user-supplied. Licensing and download URLs should not be guessed by a lab script.
- Installer signature checks are part of the exercise. `-SkipSignatureCheck` exists for controlled edge cases, not as the normal path.

## Parameters, switches and reruns

A switch such as `-Install`, `-Create`, `-Enable` or `-Remove` is an explicit opt-in. Parameters such as `-ComputerName`, `-Port` or `-DnsServers` carry environment-specific values. Scripts that can affect connectivity or broad scope use additional acknowledgement switches rather than guessing what you intended.

Most scripts are designed to be rerun. They inspect the real Windows state and either report that the requested state already exists, make the requested change, or return a clear `[SKIP]` when an optional prerequisite is absent.

## Microsoft Learn

- [Windows Server deployment, configuration, and administration](https://learn.microsoft.com/en-us/training/paths/windows-server-deployment-configuration-administration/)
- [Get started with Windows PowerShell](https://learn.microsoft.com/en-us/training/paths/get-started-windows-powershell/)

For the course-wide mapping, see [Microsoft Learn references](../docs/microsoft-learn.md).
