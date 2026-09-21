# Execution model

## Whole script or line by line

The files are written so a topic can be run as a complete script or read and executed step by step. Native Windows commands remain visible; the shared module mainly provides consistent status output, prerequisite checks and a few safe discovery helpers.

## Defaults

A script with dangerous or environment-specific behavior should be read-only or skip by default. Examples:

- no disk number is guessed;
- no physical NIC is selected for an external Hyper-V switch;
- no cluster is created without two real nodes and validation acknowledgement;
- no forest is created without `-Create`;
- no DNS/DHCP failure is injected before a clean baseline is recorded.

## Optional hosts

Cross-host scripts require a distinct target. Passing the current hostname, `localhost` or leaving the host unconfigured should not accidentally turn a two-machine exercise into a misleading local test.

## Restart boundaries

Scripts do not try to survive reboots automatically. Restart, sign in again, and run the next script.

## Error handling

Expected missing capabilities are usually `[SKIP]`. Unexpected state conflicts are errors because silently reconciling them could modify infrastructure the course did not create.
