# Module 2 - Active Directory

The default `Run-Module.ps1` path is conservative. Environment-specific, destructive or scenario scripts are run separately with explicit parameters.

## Files

- `Run-Module.ps1`
- `01-install-adds.ps1`
- `02-create-forest.ps1`
- `03-domain-baseline.ps1`
- `04-group-policy.ps1`
- `05-optional-domain-join.ps1`
- `06-ad-health.ps1`
- `07-ad-object-operations.ps1`
- `08-domain-password-policy.ps1`
- `09-gpo-registry-and-client-refresh.ps1`


## Baseline build

The default runner only inspects the baseline. Build the course-scoped OUs, ordinary users and security group explicitly:

```powershell
.\03-domain-baseline.ps1 -CreateBaseline
```

Create the optional course administrator separately when you need it:

```powershell
.\03-domain-baseline.ps1 -CreateCourseAdmin
```

Adding that account to Domain Admins requires the separate `-AddCourseAdminToDomainAdmins` switch and should be used only for the specific privileged-access demonstration.

For parameter help, use a concrete script name, for example `Get-Help .\03-domain-baseline.ps1 -Full`. Read the script header before running a changing action.
