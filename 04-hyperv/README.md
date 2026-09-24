# Module 4 - Hyper-V

Module 4 builds a small virtualization lab with Hyper-V. It covers host readiness, virtual switches, Windows and Linux guests, checkpoints, nested virtualization, resource metering, troubleshooting and cleanup.

## What you will practice

- Install and inspect Hyper-V on the current Windows Server.
- Understand internal, external and NAT-backed virtual networking.
- Create generation 2 Windows/Linux guests from explicit media paths.
- Use checkpoints and exports deliberately instead of treating them as backups.
- Inspect nested virtualization and advanced VM settings.
- Clean up only lab-owned virtual infrastructure.

## Before you start

- The host must support Hyper-V. A cloud VM also needs nested virtualization support from its VM size/platform.
- Guest creation requires installation media. Put local paths in `config\LabConfig.psd1` when useful.
- Creating an external switch can interrupt remote connectivity, so the script requires an explicit physical adapter and acknowledgement.

## Start here

From the repository root, run the module entry point first:

```powershell
.\04-hyperv\Run-Module.ps1
```

The runner uses the safe/default path. A script that needs a real hostname, disk number, IP address, credential, destructive action or connectivity-changing acknowledgement is left for you to run explicitly.

If a command is unfamiliar, use PowerShell help before running it:

```powershell
Get-Help .\04-hyperv\<script-name>.ps1 -Full
```

## Script guide

| Script | What it is for | Important inputs |
| --- | --- | --- |
| `01-install-hyperv.ps1` | Inspect or install the Hyper-V role | `-Install`, `-Restart` |
| `02-virtual-networking.ps1` | Build an internal virtual switch, gateway and NAT | `-Create`, `-SwitchName`, `-NatName`, `-GatewayAddress`, `-PrefixLength`, `-NatPrefix` |
| `03-create-windows-guest.ps1` | Create a course Windows guest from an explicit ISO | `-VMName`, `-SwitchName`, `-IsoPath`, `-VhdSize`, `-StartupMemory`, `-MaximumMemory`, `-ProcessorCount`, `-Create`, `-Start` |
| `04-create-linux-guest.ps1` | Create a course Linux guest from an explicit ISO | `-VMName`, `-SwitchName`, `-IsoPath`, `-VhdSize`, `-StartupMemory`, `-ProcessorCount`, `-Create`, `-Start` |
| `05-vm-lifecycle.ps1` | Practice checkpoints, restore, removal and export | `-VMName`, `-CheckpointName`, `-CreateCheckpoint`, `-RestoreCheckpoint`, `-RemoveCheckpoint`, `-ExportPath` |
| `06-nested-virtualization.ps1` | Inspect or enable nested virtualization on an offline VM | `-VMName`, `-Enable` |
| `07-external-switch.ps1` | Create an external switch only with an explicit physical adapter | `-Create`, `-SwitchName`, `-NetAdapterName`, `-IUnderstandConnectivityImpact` |
| `08-vm-advanced-operations.ps1` | Work with startup/stop actions, notes and resource metering | `-VMName`, `-Notes`, `-AutomaticStartAction`, `-AutomaticStopAction`, `-Measure`, `-ResetMeter` |
| `09-hyperv-troubleshooting.ps1` | Inspect host, VM, switch, event and service state | `-VMName` |
| `10-cleanup.ps1` | Remove only AZ802-prefixed Hyper-V objects | `-Remove` |
| `Run-Module.ps1` | Run the module scripts that are safe with default parameters | None |

## Examples

```powershell
cd .\04-hyperv

# Inspect Hyper-V state, then install when appropriate
.\01-install-hyperv.ps1
.\01-install-hyperv.ps1 -Install

# Create the course internal switch/NAT
.\02-virtual-networking.ps1 -Create

# Create a Windows guest from explicit media
.\03-create-windows-guest.ps1 -Create -IsoPath 'C:\ISO\WindowsServer.iso'

# Create a Linux guest
.\04-create-linux-guest.ps1 -Create -IsoPath 'C:\ISO\ubuntu-server.iso'

# Inspect one VM when troubleshooting
.\09-hyperv-troubleshooting.ps1 -VMName 'AZ802-WIN01'
```

## What to pay attention to

- A Hyper-V switch is Layer 2 connectivity. NAT/routing is a separate function.
- Nested virtualization means the guest itself can expose virtualization extensions to another hypervisor layer.
- External switch creation is one of the few operations that can cut off an RDP session. Treat that warning literally.

## Parameters, switches and reruns

A switch such as `-Install`, `-Create`, `-Enable` or `-Remove` is an explicit opt-in. Parameters such as `-ComputerName`, `-Port` or `-DnsServers` carry environment-specific values. Scripts that can affect connectivity or broad scope use additional acknowledgement switches rather than guessing what you intended.

Most scripts are designed to be rerun. They inspect the real Windows state and either report that the requested state already exists, make the requested change, or return a clear `[SKIP]` when an optional prerequisite is absent.

## Microsoft Learn

- [Manage virtual machines](https://learn.microsoft.com/en-us/training/paths/manage-virtual-machines/)
- [Windows Server Hyper-V and Virtualization](https://learn.microsoft.com/en-us/training/paths/windows-server-hyper-v-virtualization/)

For the course-wide mapping, see [Microsoft Learn references](../docs/microsoft-learn.md).
