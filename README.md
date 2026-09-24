# AZ-802 Windows Server Course Labs

Instructor-developed lab scripts for **AZ-802: Administer Windows Server**.

Hands-on Windows Server labs built for **AZ-802: Administering Windows Server** and for the practical administration work behind the exam objectives.

> **Instructor:** Shayan Ghasemnezhad  
> **Microsoft Certified Trainer (MCT)**  
> _Microsoft Certified: Azure Solutions Architect Expert_ · _AWS Certified Solutions Architect - Professional_

This repository is built for live teaching. Each topic script can be executed as a whole or opened and run step by step in Windows PowerShell.

## Lab model

The default lab is deliberately small:

- one Windows Server VM is enough for most exercises;
- a second Windows Server, Windows client, Linux guest, Hyper-V guest or Azure resource is optional;
- hostnames, domain state, adapters, roles and IP configuration are discovered at runtime where practical;
- environment-specific or destructive actions require explicit values or switches;
- missing optional machines produce a clear `[SKIP]` instead of an unexplained failure;
- course-created objects use `AZ802-` names or live under `C:\AZ802` where practical.

`shayawn.local` is a **fresh-lab default**, not a runtime assumption. If the machine already belongs to a domain, the scripts use the domain Windows reports.

## Start with a fresh Windows Server

Open **Windows PowerShell 5.1 as Administrator** from the repository root.

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1
```

On Desktop Experience, install Chrome, Firefox ESR and Visual Studio Code:

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -InstallDesktopTools
```

Add Sysinternals and download a verified Ubuntu Server LTS ISO when useful:

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 `
    -InstallDesktopTools `
    -IncludeSysinternals `
    -DownloadUbuntuIso
```

Desktop tools are skipped on Server Core. Windows Server installation media is not guessed or scraped from an unstable licensing page; place a licensed/evaluation ISO on disk and set its path in local configuration.

## Local configuration

Copy the example only when machine-specific values are useful:

```powershell
Copy-Item .\config\LabConfig.example.psd1 .\config\LabConfig.psd1
notepad .\config\LabConfig.psd1
```

Example:

```powershell
@{
    DefaultDomainName = 'shayawn.local'
    DefaultNetBIOSName = 'SHAYAWN'

    PeerWindowsHost = 'SERVER02'
    WindowsClient = 'WIN11'
    LinuxHost = $null

    WindowsServerIso = 'C:\ISO\WindowsServer.iso'
    LinuxIso = $null
    BackupTarget = $null

    LabRoot = 'C:\AZ802'
}
```

`$null` simply means that optional capability is not configured. `config\LabConfig.psd1` is ignored by Git. Do not put passwords, private keys, tokens or tenant secrets in it.

## Course map

| Folder | Focus | Microsoft Learn |
| --- | --- | --- |
| [`00-environment-preparation`](00-environment-preparation/) | Preflight, optional tools and media | [Windows Server deployment and administration](https://learn.microsoft.com/en-us/training/paths/windows-server-deployment-configuration-administration/) |
| [`01-initial-configuration`](01-initial-configuration/) | Local accounts, network, DNS client, time, firewall, RDP | [Windows Server deployment and administration](https://learn.microsoft.com/en-us/training/paths/windows-server-deployment-configuration-administration/) |
| [`02-active-directory`](02-active-directory/) | AD DS, forest/domain, users/groups/OUs, GPO, domain join | [Deploy and manage AD DS](https://learn.microsoft.com/en-us/training/paths/deploy-manage-active-directory-domain-services/) |
| [`03-remote-administration`](03-remote-administration/) | PowerShell, WinRM, SSH, Windows Admin Center | [Manage Windows Server instances and workloads](https://learn.microsoft.com/en-us/training/paths/manage-windows-server-instances-workloads-hybrid-environment/) |
| [`04-hyperv`](04-hyperv/) | Hyper-V, virtual networking, guests, lifecycle | [Manage virtual machines](https://learn.microsoft.com/en-us/training/paths/manage-virtual-machines/) |
| [`05-network-services`](05-network-services/) | DNS, DHCP, RDP, IIS, troubleshooting scenarios | [Windows Server Network Infrastructure](https://learn.microsoft.com/en-us/training/paths/windows-server-network-infrastructure/) |
| [`06-storage`](06-storage/) | SMB/NTFS, FSRM, NFS, iSCSI, DFS, backup, clustering | [Manage storage and file services](https://learn.microsoft.com/en-us/training/paths/manage-storage-file-services/) |
| [`07-security-monitoring-ir`](07-security-monitoring-ir/) | Hardening, auditing, monitoring, troubleshooting, IR | [Secure Windows Server infrastructure](https://learn.microsoft.com/en-us/training/paths/secure-windows-server-infrastructure/) |

A fuller mapping is in [Microsoft Learn references](docs/microsoft-learn.md).

## Repository layout

```text
az-802-windows-server-course-labs/
├── 00-environment-preparation/
├── 01-initial-configuration/
├── 02-active-directory/
├── 03-remote-administration/
├── 04-hyperv/
├── 05-network-services/
├── 06-storage/
├── 07-security-monitoring-ir/
├── common/
├── config/
├── docs/
└── tests/
```

Each numbered module has a `Run-Module.ps1` entry point. The default runner path is intentionally conservative. Scripts that create a forest, change networking, format disks, break a service, build a cluster or perform other environment-specific work are run separately with explicit parameters.

## Script behavior

The common rhythm is:

1. inspect the current state;
2. verify prerequisites;
3. make only the requested change;
4. verify the resulting state;
5. print the next useful action.

Example output:

```text
Step 2 | Create or verify the course SMB share
[OK] SMB share AZ802-Share01 already exists. No change required.
```

An unavailable optional machine looks like this:

```text
[SKIP] No peer Windows Server is configured. DFS Replication requires two servers.
```

## Idempotency and scenario baselines

Normal idempotency is based on Windows state. The repository does not keep a hidden database that claims something exists when Windows disagrees.

A few reversible failure scenarios deliberately save a **visible repair baseline** under `C:\AZ802\State` before breaking anything. That state is part of the lab. It records the clean setting so repair does not guess.

Examples include DNS redirection, DHCP bad-DNS options and the RDP scenario.

## Reboots are hard boundaries

Forest promotion, Hyper-V installation, computer rename and domain join can require a restart. The scripts stop cleanly and tell you to restart. They do not create hidden scheduled tasks to resume themselves.

## Failure and security scenarios

Scenario scripts use explicit phases such as:

```powershell
-Phase Build
-Phase Break
-Phase Observe
-Phase Repair
-Phase Verify
```

The normal module runners do **not** quietly break DNS, expose IIS content, delete AD objects, damage files or isolate an adapter.

## Optional Linux labs

Linux-native work stays Linux-native:

```bash
./04-hyperv/linux/docker-demo.sh
./04-hyperv/linux/network-checks.sh 192.168.100.1 192.168.100.10
./05-network-services/linux/nmap-lab.sh 192.168.100.10
./06-storage/linux/nfs-client.sh 192.168.100.1 AZ802-NFS01
```

The helper scripts use `apt`, `dnf` or `yum` when the package name is straightforward. Unsupported distributions stop with a clear message instead of assuming Ubuntu.

## Validation

On Windows PowerShell 5.1:

```powershell
.\tests\Parse-AllScripts.ps1
.\tests\Repository-Hygiene.ps1
Invoke-Pester .\tests\Repository.Tests.ps1
```

With PSScriptAnalyzer installed:

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\tests\PSScriptAnalyzerSettings.psd1
```

The included GitHub Actions workflow performs static validation on a Windows runner. It does not pretend hosted CI can reproduce a real AD DS, Hyper-V, DFS, iSCSI or failover-clustering lab.

## Documentation

- [Lab topology and runtime model](docs/topology.md)
- [Execution model](docs/execution-model.md)
- [Environment preparation](docs/environment-preparation.md)
- [Safety model](docs/safety.md)
- [Microsoft Learn references](docs/microsoft-learn.md)

## License

MIT. See [LICENSE](LICENSE).
