# Module 7 - Security, monitoring and incident response

Module 7 focuses on visibility and controlled response. It covers Defender, Windows Firewall, LAPS, SMB/certificate settings, audit policy, events, performance, AD troubleshooting, packet capture, event forwarding, evidence collection and small incident-response exercises.

## What you will practice

- Inspect security posture before making hardening changes.
- Use Windows LAPS and privileged-access concepts in an AD lab.
- Configure focused auditing and read useful events.
- Collect performance/network evidence and create repeatable baselines.
- Practice AD recovery, failed-logon investigation and packet capture.
- Perform containment only against explicit, validated targets.

## Before you start

- Several security changes are domain- or forest-wide. The scripts require extra acknowledgement for those operations.
- Packet capture and evidence collection should be targeted. More data is not automatically better data.
- Containment can disconnect a host. Read the selected action and target before running it.

## Start here

From the repository root, run the module entry point first:

```powershell
.\07-security-monitoring-ir\Run-Module.ps1
```

The runner uses the safe/default path. A script that needs a real hostname, disk number, IP address, credential, destructive action or connectivity-changing acknowledgement is left for you to run explicitly.

If a command is unfamiliar, use PowerShell help before running it:

```powershell
Get-Help .\07-security-monitoring-ir\<script-name>.ps1 -Full
```

## Script guide

| Script | What it is for | Important inputs |
| --- | --- | --- |
| `01-updates-defender-firewall.ps1` | Inspect update, Defender and firewall state; optional signature update/scan | `-UpdateSignatures`, `-QuickScan` |
| `02-laps-and-privileged-access.ps1` | Inspect Windows LAPS and deliberately prepare/read managed credentials | `-PrepareAD`, `-IUnderstandForestSchemaChange`, `-AllowedPrincipals`, `-ComputerName`, `-ShowPlainTextPassword` |
| `03-smb-and-certificates.ps1` | Inspect SMB/certificates and opt into hardening changes | `-DisableSmb1`, `-ShareName`, `-EnableShareEncryption`, `-DnsName`, `-CreateCertificate` |
| `04-auditing-and-events.ps1` | Inspect audit policy/events and optionally configure/export them | `-ConfigureLogonAuditing`, `-ShowAllAuditPolicy`, `-Export` |
| `05-performance-and-network.ps1` | Sample performance, process, network and service state | `-Target` |
| `06-ad-troubleshooting.ps1` | Read AD diagnostics and optionally refresh/report Group Policy | `-RefreshPolicy` |
| `07-ad-recycle-bin-scenario.ps1` | Enable AD Recycle Bin deliberately and run a scoped delete/restore exercise | `-EnableFeature`, `-IUnderstandForestWideChange`, `-Phase` |
| `08-incident-response-evidence.ps1` | Collect a timestamped read-only evidence bundle | None |
| `09-pktmon.ps1` | Start or stop an explicit pktmon capture under C:\AZ802 | `-Port`, `-StartCapture`, `-StopCapture` |
| `10-rdp-failed-logon-scenario.ps1` | Build, observe and repair a controlled failed-logon scenario | `-Phase`, `-Password`, `-RestrictRemoteAddress` |
| `11-windows-event-forwarding.ps1` | Inspect or prepare Windows Event Forwarding prerequisites | `-Role` |
| `12-course-health-check.ps1` | Run a broad read-only course health check | None |
| `13-security-policy-and-firewall.ps1` | Export security policy or create a scoped course firewall rule | `-ExportPolicy`, `-Port` |
| `14-openssh-security.ps1` | Inspect or reuse the Module 3 OpenSSH setup for security work | `-InstallServer`, `-ConfigureServer`, `-TargetUser`, `-PublicKey` |
| `15-protected-users-and-vbs.ps1` | Inspect VBS and manage an explicit course user in Protected Users | `-UserName`, `-OpenMsInfo` |
| `16-performance-collector.ps1` | Sample counters or create a logman collector | `-Sample`, `-SampleInterval`, `-MaxSamples`, `-CreateLogmanCollector`, `-ReplaceCollector` |
| `17-controlled-containment.ps1` | Run one explicit, validated containment action | `-Action`, `-Name`, `-Port`, `-AdapterName`, `-AllowNonCourseIdentity`, `-IUnderstandConnectivityLoss` |
| `18-admin-tool-launchers.ps1` | Open built-in administration interfaces without changing settings | `-WindowsUpdate`, `-SConfig`, `-EventViewer`, `-ReliabilityMonitor` |
| `Run-Module.ps1` | Run the module scripts that are safe with default parameters | None |

## Examples

```powershell
cd .\07-security-monitoring-ir

# Safe/read-only pass
.\Run-Module.ps1

# Inspect audit policy, then explicitly enable the course logon-auditing example
.\04-auditing-and-events.ps1
.\04-auditing-and-events.ps1 -ConfigureLogonAuditing

# Collect a timestamped evidence bundle
.\08-incident-response-evidence.ps1

# Start a packet capture for one port, then stop it later
.\09-pktmon.ps1 -Port 3389 -StartCapture
.\09-pktmon.ps1 -StopCapture

# Broad read-only health check
.\12-course-health-check.ps1
```

## What to pay attention to

- Security work is easier when you have a baseline. Know what "normal" services, ports, events and performance look like before diagnosing an incident.
- Authentication failures can come from identity, DNS, time, trust, network or policy. AD troubleshooting should keep those dependencies visible.
- Evidence collection and containment are different jobs. Preserve useful state before you change it.

## Parameters, switches and reruns

A switch such as `-Install`, `-Create`, `-Enable` or `-Remove` is an explicit opt-in. Parameters such as `-ComputerName`, `-Port` or `-DnsServers` carry environment-specific values. Scripts that can affect connectivity or broad scope use additional acknowledgement switches rather than guessing what you intended.

Most scripts are designed to be rerun. They inspect the real Windows state and either report that the requested state already exists, make the requested change, or return a clear `[SKIP]` when an optional prerequisite is absent.

## Microsoft Learn

- [Secure Windows Server infrastructure](https://learn.microsoft.com/en-us/training/paths/secure-windows-server-infrastructure/)
- [Monitor and Troubleshoot Windows Server Environments](https://learn.microsoft.com/en-us/training/paths/monitor-troubleshoot-windows-server-environments/)
- [AZ-802 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-802)

For the course-wide mapping, see [Microsoft Learn references](../docs/microsoft-learn.md).
