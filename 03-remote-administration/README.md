# Module 3 - Remote administration

Module 3 is about managing Windows Server without living inside an RDP session. The scripts cover PowerShell discovery, WinRM/PowerShell remoting, OpenSSH, Windows Admin Center checks, service/feature work and an Azure context reference.

## What you will practice

- Use PowerShell help and discovery instead of memorizing every cmdlet.
- Understand WinRM, WSMan and PowerShell remoting.
- Install and configure OpenSSH on Windows when the lab needs SSH.
- Troubleshoot remote access in a useful order: name resolution, reachability, port, service, authentication.
- Inspect Windows Admin Center and Azure PowerShell context without assuming either is installed.

## Before you start

- Remote administration needs both network reachability and a listening/configured service.
- WinRM HTTP normally uses TCP 5985. HTTPS remoting uses 5986 when configured.
- OpenSSH server uses TCP 22 and has its own service, config and authorization model.

## Start here

From the repository root, run the module entry point first:

```powershell
.\03-remote-administration\Run-Module.ps1
```

The runner uses the safe/default path. A script that needs a real hostname, disk number, IP address, credential, destructive action or connectivity-changing acknowledgement is left for you to run explicitly.

If a command is unfamiliar, use PowerShell help before running it:

```powershell
Get-Help .\03-remote-administration\<script-name>.ps1 -Full
```

## Script guide

| Script | What it is for | Important inputs |
| --- | --- | --- |
| `01-powershell-administration.ps1` | Use PowerShell to inspect the server and write a small report | None |
| `02-winrm-remoting.ps1` | Enable/test WinRM and run commands on an optional peer | `-EnableLocalRemoting`, `-ComputerName`, `-Credential` |
| `03-openssh.ps1` | Install/configure OpenSSH and optional public-key access | `-InstallServer`, `-ConfigureServer`, `-TargetUser`, `-PublicKey` |
| `04-windows-admin-center.ps1` | Inspect Windows Admin Center services, listeners and firewall rules | None |
| `05-remote-troubleshooting.ps1` | Walk through DNS, ICMP, TCP and WSMan troubleshooting | `-ComputerName` |
| `06-powershell-discovery-and-profile.ps1` | Practice Get-Command, Get-Help, Get-Member and profile discovery | `-SetRemoteSigned` |
| `07-feature-and-service-operations.ps1` | Inspect or change one Windows feature/service deliberately | `-FeatureName`, `-FeatureAction`, `-RestartService` |
| `08-azure-vm-reference.ps1` | Show the current Azure PowerShell context when available | None |
| `Run-Module.ps1` | Run the module scripts that are safe with default parameters | None |

## Examples

```powershell
cd .\03-remote-administration

# Safe/read-only module path
.\Run-Module.ps1

# Enable local PowerShell remoting
.\02-winrm-remoting.ps1 -EnableLocalRemoting

# Test an explicit peer
.\05-remote-troubleshooting.ps1 -ComputerName 'SERVER02'

# Install and configure OpenSSH Server
.\03-openssh.ps1 -InstallServer -ConfigureServer

# Inspect or deliberately change one feature
.\07-feature-and-service-operations.ps1 -FeatureName 'Web-Server' -FeatureAction Install
```

## What to pay attention to

- RDP gives you an interactive desktop. PowerShell remoting gives you a remote PowerShell session. SSH is a separate encrypted remote-access protocol. They solve overlapping problems through different stacks.
- A firewall rule does not create a listener. A listener does not guarantee the network path or authentication works. Check each layer separately.

## Parameters, switches and reruns

A switch such as `-Install`, `-Create`, `-Enable` or `-Remove` is an explicit opt-in. Parameters such as `-ComputerName`, `-Port` or `-DnsServers` carry environment-specific values. Scripts that can affect connectivity or broad scope use additional acknowledgement switches rather than guessing what you intended.

Most scripts are designed to be rerun. They inspect the real Windows state and either report that the requested state already exists, make the requested change, or return a clear `[SKIP]` when an optional prerequisite is absent.

## Microsoft Learn

- [Manage Windows Server instances and workloads in a hybrid environment](https://learn.microsoft.com/en-us/training/paths/manage-windows-server-instances-workloads-hybrid-environment/)
- [Administer remote computers by using Windows PowerShell](https://learn.microsoft.com/en-us/training/paths/administer-remote-computers-use-windows-powershell/)
- [Get started with OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)

For the course-wide mapping, see [Microsoft Learn references](../docs/microsoft-learn.md).
