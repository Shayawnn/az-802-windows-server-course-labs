# Module 1 - Initial configuration

Module 1 is the "know your server before you touch it" part of the course. It covers identity, local accounts, networking, DNS client settings, time, the computer name, Windows Firewall and Remote Desktop.

## What you will practice

- Read the current Windows Server state with native tools.
- Work with local users and local administrator membership.
- Understand DHCP versus static addressing and the role of DNS client settings.
- Change the computer name safely and treat restart as a real boundary.
- Inspect Windows Firewall and enable RDP/ICMP only when the lab calls for it.

## Before you start

- Use a disposable or controlled Windows Server lab.
- Run changing actions from an elevated Windows PowerShell 5.1 console.
- If you are connected remotely, be careful with IP, gateway, firewall and adapter changes.

## Start here

From the repository root, run the module entry point first:

```powershell
.\01-initial-configuration\Run-Module.ps1
```

The runner uses the safe/default path. A script that needs a real hostname, disk number, IP address, credential, destructive action or connectivity-changing acknowledgement is left for you to run explicitly.

If a command is unfamiliar, use PowerShell help before running it:

```powershell
Get-Help .\01-initial-configuration\<script-name>.ps1 -Full
```

## Script guide

| Script | What it is for | Important inputs |
| --- | --- | --- |
| `01-inventory-and-preflight.ps1` | Inventory the current server before changing anything | None |
| `02-local-accounts.ps1` | Create, elevate or remove a course-scoped local account | `-UserName`, `-Password`, `-AddToAdministrators`, `-Remove` |
| `03-network-dns-time.ps1` | Inspect networking and optionally set IPv4 or DNS values | `-IPAddress`, `-PrefixLength`, `-DefaultGateway`, `-DnsServers`, `-IUnderstandConnectivityLoss` |
| `04-computer-name.ps1` | Inspect or rename the computer | `-NewName`, `-Restart` |
| `05-firewall-and-rdp.ps1` | Inspect firewall/RDP state and optionally enable RDP with NLA | `-EnableRdp` |
| `06-supplemental-system-administration.ps1` | Inspect update/system state; optionally allow ICMP or set a time peer | `-EnableIcmp`, `-TimePeer` |
| `Run-Module.ps1` | Run the module scripts that are safe with default parameters | None |

## Examples

```powershell
cd .\01-initial-configuration

# Safe/read-only pass through the module
.\Run-Module.ps1

# Create a course local account and add it to local Administrators
.\02-local-accounts.ps1 -UserName 'AZ802-LocalAdmin' -AddToAdministrators

# Point the server at an explicit DNS server from your lab
$DnsServer = Read-Host 'DNS server IPv4 address'
.\03-network-dns-time.ps1 -DnsServers $DnsServer

# Rename, then restart separately when you are ready
.\04-computer-name.ps1 -NewName 'AZ802-SRV01'

# Enable RDP with NLA and the built-in firewall rules
.\05-firewall-and-rdp.ps1 -EnableRdp

# Allow ICMP echo for the lab
.\06-supplemental-system-administration.ps1 -EnableIcmp
```

## What to pay attention to

- Local accounts and domain accounts are different security databases. A domain controller does not use the normal local SAM account model.
- DNS is part of identity in a Windows domain. "Internet DNS works" does not mean "Active Directory DNS works."
- Azure NSGs and Windows Firewall are separate layers. Allowing traffic in one layer does not change the other.

## Parameters, switches and reruns

A switch such as `-Install`, `-Create`, `-Enable` or `-Remove` is an explicit opt-in. Parameters such as `-ComputerName`, `-Port` or `-DnsServers` carry environment-specific values. Scripts that can affect connectivity or broad scope use additional acknowledgement switches rather than guessing what you intended.

Most scripts are designed to be rerun. They inspect the real Windows state and either report that the requested state already exists, make the requested change, or return a clear `[SKIP]` when an optional prerequisite is absent.

## Microsoft Learn

- [Windows Server deployment, configuration, and administration](https://learn.microsoft.com/en-us/training/paths/windows-server-deployment-configuration-administration/)
- [Get started with Windows PowerShell](https://learn.microsoft.com/en-us/training/paths/get-started-windows-powershell/)

For the course-wide mapping, see [Microsoft Learn references](../docs/microsoft-learn.md).
