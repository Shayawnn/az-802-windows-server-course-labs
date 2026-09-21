# Lab topology and runtime model

The scripts are **single-server first**.

The current Windows Server is the primary execution environment. Its actual hostname, domain membership, active adapter and installed roles are treated as runtime facts. Names such as `AZ802-WIN01` and `AZ802-LINUX01` are disposable course object names, not promises that those machines already exist.

Optional capabilities can be recorded in `config/LabConfig.psd1`:

- `PeerWindowsHost` — a second Windows Server for remoting, DFS Replication or clustering;
- `WindowsClient` — an optional client for domain join, DHCP/RDP observations and cross-host checks;
- `LinuxHost` — an optional Linux machine or Hyper-V guest for Nmap/NFS/Docker work;
- `WindowsServerIso` and `LinuxIso` — local media paths;
- `BackupTarget` — an optional backup destination.

If an optional capability is absent, the related script should return `[SKIP]` rather than inventing a hostname or treating the missing machine as a failure.

The fresh-forest example domain is `shayawn.local`, but existing domain state wins. Scripts that work inside Active Directory derive the real distinguished name from `Get-ADDomain` instead of hardcoding `DC=shayawn,DC=local`.
