# Environment preparation

Use this module on a fresh Windows Server before the course labs. The default runner performs a read-only preflight; software installation and media downloads are opt-in.

## Files

- `Run-EnvironmentPreparation.ps1` - preflight plus optional preparation tasks
- `01-preflight.ps1` - Windows edition, PowerShell, elevation, networking, storage and virtualization checks
- `02-install-desktop-tools.ps1` - Chrome, Firefox and Visual Studio Code on Desktop Experience
- `03-install-sysinternals.ps1` - optional Sysinternals download and verification
- `04-download-lab-media.ps1` - optional verified Ubuntu Server ISO download and Windows Server ISO path check

## Typical use

```powershell
.\Run-EnvironmentPreparation.ps1
```

On Desktop Experience, add the classroom desktop tools:

```powershell
.\Run-EnvironmentPreparation.ps1 -InstallDesktopTools
```

For the fuller optional setup:

```powershell
.\Run-EnvironmentPreparation.ps1 `
    -InstallDesktopTools `
    -IncludeSysinternals `
    -DownloadUbuntuIso
```

Server Core skips GUI applications cleanly. Windows Server installation media is not downloaded automatically; provide a legitimate local ISO path in `config\LabConfig.psd1` when Hyper-V guest labs need it.
