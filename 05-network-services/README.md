# Module 5 - DNS, DHCP, RDP and IIS

Module 5 brings together the services that make a Windows Server environment usable on the network. It covers DNS, DHCP, RDP and IIS, then uses small reversible failure scenarios to make troubleshooting visible.

## What you will practice

- Create and inspect DNS zones, records, reverse lookup and forwarding.
- Install/authorize DHCP, build a scope, options and reservations.
- Enable and reason about Remote Desktop access.
- Install IIS, create an isolated course site and add HTTPS.
- Practice failure, observation, repair and verification instead of jumping straight to the fix.

## Before you start

- DNS and DHCP can affect real clients. Use a lab network and explicit scope values.
- For Azure-hosted labs, Azure NSGs and Windows Firewall are independent controls.
- Public reachability also requires a service to be listening. Opening a port alone does not install or start IIS, SSH or WinRM.

## Start here

From the repository root, run the module entry point first:

```powershell
.\05-network-services\Run-Module.ps1
```

The runner uses the safe/default path. A script that needs a real hostname, disk number, IP address, credential, destructive action or connectivity-changing acknowledgement is left for you to run explicitly.

If a command is unfamiliar, use PowerShell help before running it:

```powershell
Get-Help .\05-network-services\<script-name>.ps1 -Full
```

## Script guide

| Script | What it is for | Important inputs |
| --- | --- | --- |
| `01-dns.ps1` | Inspect DNS; optionally install the role, create a zone or add an A record | `-Install`, `-ZoneName`, `-CreateZone`, `-RecordName`, `-IPv4Address` |
| `02-dhcp.ps1` | Inspect DHCP; optionally install, authorize and create a scope/options | `-Install`, `-AuthorizeInAD`, `-ScopeName`, `-StartRange`, `-EndRange`, `-SubnetMask`, `-DnsServers`, `-Router`, `-DnsDomain` |
| `03-rdp.ps1` | Inspect or enable Remote Desktop with NLA | `-Enable` |
| `04-iis.ps1` | Inspect/install IIS and create a course site on an explicit port | `-Install`, `-CreateSite`, `-Port` |
| `05-iis-https.ps1` | Create a course certificate and exact SNI HTTPS binding | `-SiteName`, `-HostName`, `-Port`, `-CertificateFriendlyName`, `-Create` |
| `06-dns-failure-scenario.ps1` | Break and repair a course DNS record using a saved baseline | `-Phase`, `-ZoneName`, `-RecordName`, `-GoodAddress`, `-BadAddress` |
| `07-dhcp-bad-dns-scenario.ps1` | Break and repair DHCP option 006 using a saved baseline | `-Phase`, `-ScopeId`, `-GoodDnsServer`, `-BadDnsServer`, `-ResetBaseline` |
| `08-iis-exposure-scenario.ps1` | Demonstrate and repair directory browsing exposure on the course site | `-Phase` |
| `09-dns-advanced.ps1` | Practice CNAME, reverse zones and forwarding without overwriting conflicts | `-ZoneName`, `-AliasName`, `-AliasTarget`, `-ReverseNetwork`, `-Forwarder` |
| `10-dhcp-reservation.ps1` | Create a reservation from real client values | `-ScopeId`, `-IPAddress`, `-ClientId` |
| `11-rdp-and-rds-advanced.ps1` | Manage RDP group membership or install RDS deliberately | `-Principal`, `-InstallRds` |
| `12-iis-advanced.ps1` | Practice virtual directories, Windows auth and HSTS | `-CreateVirtualDirectory`, `-EnableWindowsAuthentication`, `-Location`, `-EnableHsts`, `-SiteName`, `-HstsMaxAge` |
| `13-service-health.ps1` | Read service and listener health for the module roles | None |
| `Run-Module.ps1` | Run the module scripts that are safe with default parameters | None |

## Examples

```powershell
cd .\05-network-services

# Inspect DNS and DHCP first
.\01-dns.ps1
.\02-dhcp.ps1

# Install IIS and create the isolated course site on 8080
.\04-iis.ps1 -Install -CreateSite -Port 8080

# Verify overall service/listener health
.\13-service-health.ps1

# Run the DNS scenario one phase at a time
$GoodAddress = Read-Host 'IPv4 address the demo record should normally use'
.\06-dns-failure-scenario.ps1 -Phase Build -ZoneName 'shayawn.local' -RecordName 'az802-demo' -GoodAddress $GoodAddress
.\06-dns-failure-scenario.ps1 -Phase Break -ZoneName 'shayawn.local' -RecordName 'az802-demo' -BadAddress '192.0.2.44'
.\06-dns-failure-scenario.ps1 -Phase Observe -ZoneName 'shayawn.local' -RecordName 'az802-demo'
.\06-dns-failure-scenario.ps1 -Phase Repair -ZoneName 'shayawn.local' -RecordName 'az802-demo'
.\06-dns-failure-scenario.ps1 -Phase Verify -ZoneName 'shayawn.local' -RecordName 'az802-demo'
```

## What to pay attention to

- DNS answers "what address/service name should I use?" DHCP supplies host configuration such as IP, gateway and DNS server. RDP is remote interactive access. IIS is an application service that listens on configured HTTP/HTTPS bindings.
- A `filtered` Nmap result usually means a filtering device or firewall prevented Nmap from deciding whether a service is listening. `closed` means the destination answered but no service accepted the connection.

## Parameters, switches and reruns

A switch such as `-Install`, `-Create`, `-Enable` or `-Remove` is an explicit opt-in. Parameters such as `-ComputerName`, `-Port` or `-DnsServers` carry environment-specific values. Scripts that can affect connectivity or broad scope use additional acknowledgement switches rather than guessing what you intended.

Most scripts are designed to be rerun. They inspect the real Windows state and either report that the requested state already exists, make the requested change, or return a clear `[SKIP]` when an optional prerequisite is absent.

## Microsoft Learn

- [Windows Server Network Infrastructure](https://learn.microsoft.com/en-us/training/paths/windows-server-network-infrastructure/)
- [Implement and operate an on-premises and hybrid networking infrastructure](https://learn.microsoft.com/en-us/training/paths/implement-operate-premises-hybrid/)
- [Administer Internet Information Services](https://learn.microsoft.com/en-us/training/paths/administer-internet-information-services/)

For the course-wide mapping, see [Microsoft Learn references](../docs/microsoft-learn.md).
