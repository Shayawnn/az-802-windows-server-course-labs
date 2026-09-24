# Environment preparation

`00-environment-preparation` is the starting point for a fresh Windows Server. The default run only inventories the machine. Installation and downloads are opt-in so you can see what the server already has before adding anything.

## Preflight

From the repository root:

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1
```

The preflight reports the Windows edition/install type, PowerShell version, elevation state, networking, storage and virtualization readiness.

## Optional tools

On Desktop Experience:

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -InstallDesktopTools
```

This can install Chrome, Firefox ESR and Visual Studio Code. Server Core skips GUI applications cleanly.

Add Sysinternals when the later troubleshooting labs need it:

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -IncludeSysinternals
```

The suite is expanded under `C:\AZ802\Tools\Sysinternals`.

## Optional media

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -DownloadUbuntuIso
```

Ubuntu media is discovered from the official Ubuntu 24.04 LTS release location and checked against the official SHA-256 manifest before it is accepted.

Windows Server installation media is intentionally user-supplied. Put the licensed/evaluation ISO on disk and record the local path in `config\LabConfig.psd1` if the Hyper-V labs need it.