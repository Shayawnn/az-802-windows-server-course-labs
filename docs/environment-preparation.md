# Environment preparation

`00-environment-preparation` is for a fresh Windows Server.

The default preflight is conservative. Optional switches add tools or media:

```powershell
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -InstallDesktopTools
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -IncludeSysinternals
.\00-environment-preparation\Run-EnvironmentPreparation.ps1 -DownloadUbuntuIso
```

Desktop Experience can receive Chrome, Firefox ESR and Visual Studio Code. Server Core skips GUI applications.

Sysinternals is expanded under `C:\AZ802\Tools\Sysinternals`.

Ubuntu media is discovered from the official Ubuntu 24.04 LTS release page and verified against the official `SHA256SUMS` manifest before it is accepted.

Windows Server installation media is intentionally not downloaded from an assumed public URL. Supply a licensed/evaluation ISO yourself and record its path in `config\LabConfig.psd1`.
