# Module 6 - Storage and file services

Module 6 covers local disks and volumes, SMB/NTFS, FSRM, NFS, iSCSI, Storage Spaces, DFS, backup/recovery, deduplication and a small failover-clustering path. Many of these exercises need an extra disk or second server, so the scripts skip cleanly when the lab does not have one.

## What you will practice

- Separate block storage, file systems, file sharing and namespace concepts.
- Build SMB shares and reason about share permissions versus NTFS permissions.
- Use FSRM, NFS, iSCSI, Storage Spaces and deduplication in controlled lab scope.
- Build DFS namespace/replication only when the required second host exists.
- Run backup and recovery with explicit targets and verify the restored data.
- Validate cluster prerequisites before creating anything.

## Before you start

- Never guess disk numbers. The disk script only accepts an explicitly selected RAW non-system disk.
- DFS Replication and failover clustering need a real second Windows Server.
- Backup targets, iSCSI initiators and storage pool disks must be real values from your environment.

## Start here

From the repository root, run the module entry point first:

```powershell
.\06-storage\Run-Module.ps1
```

The runner uses the safe/default path. A script that needs a real hostname, disk number, IP address, credential, destructive action or connectivity-changing acknowledgement is left for you to run explicitly.

If a command is unfamiliar, use PowerShell help before running it:

```powershell
Get-Help .\06-storage\<script-name>.ps1 -Full
```

## Script guide

| Script | What it is for | Important inputs |
| --- | --- | --- |
| `01-disks-and-volumes.ps1` | Inspect disks and format only an explicitly selected RAW non-system disk | `-DiskNumber`, `-DriveLetter`, `-Label` |
| `02-smb-and-ntfs.ps1` | Create a course SMB share and explicit NTFS access | `-Install`, `-CreateShare`, `-NtfsPrincipal` |
| `03-fsrm.ps1` | Install FSRM and build the course quota/template | `-Install`, `-CreateQuota` |
| `04-nfs-server.ps1` | Install NFS and create the course export | `-Install`, `-CreateShare` |
| `05-iscsi-target.ps1` | Install/configure a course iSCSI target with explicit initiators | `-Install`, `-Create`, `-InitiatorId`, `-Size` |
| `06-iscsi-initiator.ps1` | Prepare the initiator, connect a target and optionally initialize a RAW iSCSI disk | `-Prepare`, `-TargetPortalAddress`, `-TargetNodeAddress`, `-Connect`, `-DiskNumber` |
| `07-storage-spaces.ps1` | Create a storage pool from explicit physical-disk IDs | `-Create`, `-PhysicalDiskUniqueId`, `-Size`, `-DriveLetter` |
| `08-dfs-namespace.ps1` | Create a course DFS namespace and folder target | `-Install`, `-Create`, `-FolderTarget` |
| `09-dfs-replication.ps1` | Create a two-server DFS Replication group after peer validation | `-PeerComputerName`, `-PeerCredential`, `-Create` |
| `10-backup.ps1` | Inspect backup state or run a backup to an explicit target | `-Install`, `-BackupTarget`, `-IncludePath` |
| `11-backup-recovery.ps1` | List backup versions and restore explicit items to a recovery directory | `-BackupTarget`, `-Version`, `-Items`, `-RecoveryTarget`, `-Recover` |
| `12-storage-health.ps1` | Read disk, volume, SMB, role, event and backup health | None |
| `13-file-recovery-scenario.ps1` | Run a controlled file damage/recovery exercise under C:\AZ802 | `-Phase`, `-ResetLab` |
| `14-failover-clustering.ps1` | Validate and optionally create a two-node course cluster | `-Install`, `-SecondNode`, `-PeerCredential`, `-Validate`, `-Create`, `-ValidationReviewed`, `-StaticAddress` |
| `15-smb-client-access.ps1` | Test SMB client access and optionally map a persistent drive | `-Server`, `-ShareName`, `-MapDrive`, `-DriveName` |
| `16-smb-open-files.ps1` | List open SMB files and optionally close one explicit handle | `-FileId`, `-Close` |
| `17-windows-nfs-client.ps1` | Install Client for NFS and mount an explicit export | `-Install`, `-Server`, `-ExportName`, `-DriveLetter` |
| `18-data-deduplication.ps1` | Inspect or enable/optimize deduplication on an explicit non-system volume | `-Install`, `-Volume`, `-Enable`, `-Optimize` |
| `19-system-state-backup.ps1` | Install Windows Server Backup and run an explicit system-state backup | `-Install`, `-BackupTarget`, `-Run` |
| `Run-Module.ps1` | Run the module scripts that are safe with default parameters | None |

## Examples

```powershell
cd .\06-storage

# Inventory first
.\01-disks-and-volumes.ps1
.\12-storage-health.ps1

# Create the course SMB share and grant an explicit principal
.\02-smb-and-ntfs.ps1 -Install -CreateShare -NtfsPrincipal 'SHAYAWN\AZ802-Development'

# Initialize only a disk you have already identified as the correct RAW lab disk
Get-Disk | Format-Table Number,FriendlyName,PartitionStyle,OperationalStatus,Size
$DiskNumber = [int](Read-Host 'Verified RAW lab disk number')
.\01-disks-and-volumes.ps1 -DiskNumber $DiskNumber -DriveLetter 'F' -Label 'AZ802-DATA'

# Run the controlled file-recovery scenario
.\13-file-recovery-scenario.ps1 -Phase Build
.\13-file-recovery-scenario.ps1 -Phase Break
.\13-file-recovery-scenario.ps1 -Phase Observe
.\13-file-recovery-scenario.ps1 -Phase Repair
.\13-file-recovery-scenario.ps1 -Phase Verify
```

## What to pay attention to

- SMB is the file-sharing protocol. NTFS permissions protect files/directories on the Windows file system. Effective access can be constrained by both.
- iSCSI presents block storage over IP. NFS and SMB present file shares. DFS can provide a namespace and, separately, replication between servers.
- The clustering script runs `Test-Cluster` first and requires you to acknowledge that you reviewed validation before creation.

## Parameters, switches and reruns

A switch such as `-Install`, `-Create`, `-Enable` or `-Remove` is an explicit opt-in. Parameters such as `-ComputerName`, `-Port` or `-DnsServers` carry environment-specific values. Scripts that can affect connectivity or broad scope use additional acknowledgement switches rather than guessing what you intended.

Most scripts are designed to be rerun. They inspect the real Windows state and either report that the requested state already exists, make the requested change, or return a clear `[SKIP]` when an optional prerequisite is absent.

## Microsoft Learn

- [Manage storage and file services](https://learn.microsoft.com/en-us/training/paths/manage-storage-file-services/)
- [Windows Server high availability](https://learn.microsoft.com/en-us/training/paths/windows-server-high-availability/)
- [AZ-802 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-802)

For the course-wide mapping, see [Microsoft Learn references](../docs/microsoft-learn.md).
