# Contributing

This repository is course material first.

Before submitting a change:

- keep Windows PowerShell 5.1 compatibility unless a script explicitly says otherwise;
- keep environment-specific values as parameters or local configuration;
- do not add plaintext passwords, private keys or tenant secrets;
- do not assume a second server, client, Linux host or Azure subscription exists;
- scope disposable objects to `AZ802-` names or `C:\AZ802` where practical;
- require explicit confirmation or an explicit switch for destructive/connectivity-breaking actions;
- verify prerequisites before changing state;
- do not hide meaningful failures with blanket `SilentlyContinue` handling;
- keep runtime output useful enough to read during a live session;
- keep comments technical and local to the command they explain;
- update the relevant module README or root documentation when invocation changes.

Run the validation suite before committing:

```powershell
.\tests\Parse-AllScripts.ps1
.\tests\Repository-Hygiene.ps1
Invoke-Pester .\tests\Repository.Tests.ps1
```

PSScriptAnalyzer is also used in CI.
