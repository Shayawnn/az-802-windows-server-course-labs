# Safety model

These scripts are intended for disposable or controlled training environments.

Guardrails include:

- course-created names use `AZ802-` prefixes where practical;
- course files live under `C:\AZ802` where practical;
- boot/system disks are refused;
- RAW disk initialization requires an explicit disk number;
- system-volume deduplication is refused;
- external Hyper-V switches require an explicit physical NIC;
- non-course identity containment requires an extra opt-in;
- adapter disablement requires an explicit connectivity-loss acknowledgement;
- cluster creation requires a real second node and explicit validation acknowledgement;
- forest/schema-wide changes require explicit acknowledgement;
- reversible failure scenarios save the clean setting before breakage.

Do not run a changing script in production without reading it and adapting the parameters to the real environment.
