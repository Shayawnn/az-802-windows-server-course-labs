# Module 2 - Active Directory

Module 2 turns a standalone Windows Server into an identity platform. It covers AD DS installation, forest creation, OUs, users, groups, Group Policy, domain join, password policy and basic health checks.

## What you will practice

- Install AD DS and understand the difference between installing the role and promoting a domain controller.
- Create or inspect a forest/domain and the DNS service AD DS depends on.
- Build users, groups and OUs without hardcoding a particular domain DN.
- Apply Group Policy to a scoped OU.
- Join a separate Windows machine to the domain and verify DC discovery.
- Read AD, DNS and replication health before troubleshooting blindly.

## Before you start

- A new forest changes the identity role of the server and requires a restart.
- A domain-join client must be able to route to the domain controller and use the AD DNS server.
- For the remote join script, the target must be a separate Windows machine with WinRM reachable. Running the join locally on the client is also a valid teaching path.

## Start here

From the repository root, run the module entry point first:

```powershell
.\02-active-directory\Run-Module.ps1
```

The runner uses the safe/default path. A script that needs a real hostname, disk number, IP address, credential, destructive action or connectivity-changing acknowledgement is left for you to run explicitly.

If a command is unfamiliar, use PowerShell help before running it:

```powershell
Get-Help .\02-active-directory\<script-name>.ps1 -Full
```

## Script guide

| Script | What it is for | Important inputs |
| --- | --- | --- |
| `01-install-adds.ps1` | Inspect or install the AD DS server role | `-Install` |
| `02-create-forest.ps1` | Create a new AD DS forest and DNS service when explicitly requested | `-DomainName`, `-NetBIOSName`, `-SafeModeAdministratorPassword`, `-Create`, `-Restart` |
| `03-domain-baseline.ps1` | Build course OUs, users and groups; optionally create a course admin | `-CreateBaseline`, `-CreateCourseAdmin`, `-CourseAdminPassword`, `-AddCourseAdminToDomainAdmins`, `-CourseUserPassword` |
| `04-group-policy.ps1` | Create and link the course server-baseline GPO | None |
| `05-optional-domain-join.ps1` | Configure DNS and join a separate Windows machine through WinRM | `-ComputerName`, `-DomainName`, `-DomainDnsServer`, `-RemoteCredential`, `-DomainJoinCredential` |
| `06-ad-health.ps1` | Read domain controller, replication and DNS health | None |
| `07-ad-object-operations.ps1` | Practice scoped user/object operations | `-UserName`, `-UserAction`, `-NewPassword`, `-CreateUnixUser`, `-RemoveCourseObject` |
| `08-domain-password-policy.ps1` | Inspect or deliberately change the default domain password policy | `-Apply`, `-IUnderstandDomainWideImpact`, `-MinPasswordLength`, `-MaxPasswordAge`, `-LockoutThreshold`, `-LockoutDuration` |
| `09-gpo-registry-and-client-refresh.ps1` | Set a course GPO registry value and refresh policy | `-SetRdpPolicy`, `-RefreshLocalComputer` |
| `Run-Module.ps1` | Run the module scripts that are safe with default parameters | None |

## Examples

```powershell
cd .\02-active-directory

# Install the AD DS role
.\01-install-adds.ps1 -Install

# Review the requested forest, then create it explicitly
.\02-create-forest.ps1
.\02-create-forest.ps1 -Create

# After the required restart, build the course OUs/users/group
.\03-domain-baseline.ps1 -CreateBaseline

# Create/link the course GPO
.\04-group-policy.ps1

# Read AD/DNS/replication health
.\06-ad-health.ps1
```

## What to pay attention to

- AD DS is the directory. DNS is how domain members find domain services. Kerberos is the normal ticket-based authentication protocol. Group Policy is centralized configuration applied through AD scope.
- A client can be Windows 11 Pro/Enterprise or a Windows Server member server. For a real workstation lab, Windows 11 makes the logon and policy experience easier to see.
- The fresh-lab default is `shayawn.local`, but scripts use the domain Windows actually reports once a machine is domain joined.

## Parameters, switches and reruns

A switch such as `-Install`, `-Create`, `-Enable` or `-Remove` is an explicit opt-in. Parameters such as `-ComputerName`, `-Port` or `-DnsServers` carry environment-specific values. Scripts that can affect connectivity or broad scope use additional acknowledgement switches rather than guessing what you intended.

Most scripts are designed to be rerun. They inspect the real Windows state and either report that the requested state already exists, make the requested change, or return a clear `[SKIP]` when an optional prerequisite is absent.

## Microsoft Learn

- [Deploy and manage Active Directory Domain Services](https://learn.microsoft.com/en-us/training/paths/deploy-manage-active-directory-domain-services/)
- [Active Directory Domain Services](https://learn.microsoft.com/en-us/training/paths/active-directory-domain-services/)
- [AZ-802 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-802)

For the course-wide mapping, see [Microsoft Learn references](../docs/microsoft-learn.md).
