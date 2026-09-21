@{
    # Used only when creating a new forest. Existing domain membership wins at runtime.
    DefaultDomainName = 'shayawn.local'
    DefaultNetBIOSName = 'SHAYAWN'

    # Optional peer machines. Leave $null when they do not exist.
    PeerWindowsHost = $null
    WindowsClient = $null
    LinuxHost = $null

    # Optional media and storage paths. Keep machine-specific values in LabConfig.psd1.
    WindowsServerIso = $null
    LinuxIso = $null
    BackupTarget = $null

    # Course-owned filesystem root.
    LabRoot = 'C:\AZ802'
}
