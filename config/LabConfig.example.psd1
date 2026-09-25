@{
    # This is a PowerShell data file. It records optional facts about your lab.
    # Copy this file to LabConfig.psd1 and change only the values you actually have.
    # LabConfig.psd1 is ignored by Git. Do not store passwords, tokens or private keys here.

    # Used only when creating a brand-new forest. Existing domain membership wins at runtime.
    DefaultDomainName = 'shayawn.local'
    DefaultNetBIOSName = 'SHAYAWN'

    # Optional peer machines. $null means that capability is not configured.
    # PeerWindowsHost is useful for remoting, DFS Replication and clustering.
    # WindowsClient is useful for domain join, policy and client-side tests.
    # LinuxHost is useful for Nmap, NFS and Docker exercises.
    PeerWindowsHost = $null
    WindowsClient = $null
    LinuxHost = $null

    # Optional media and storage paths. Use real local paths/targets from your lab.
    WindowsServerIso = $null
    LinuxIso = $null
    BackupTarget = $null

    # Course-owned filesystem root.
    LabRoot = 'C:\AZ802'
}
