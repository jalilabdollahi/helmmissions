# The Upgrade That Undid Itself

## What broke
The 0.5 chart set `report.schedule: "every 15 minutes"`. The API server rejected the CronJob, so the
upgrade failed. Because the pipeline used the automatic-rollback flag, Helm immediately created a
third revision that is a copy of revision 1. The release ends up `deployed`, which hides the failure
unless you read the history.

## Why Helm behaves this way
Every upgrade attempt creates a new revision (a new `sh.helm.release.v1.<name>.vN` Secret) *before*
anything is applied. If applying fails, that revision is marked `failed` with the error as its
description. With `--rollback-on-failure` (Helm 4) or `--atomic` (Helm 3), Helm then performs
`helm rollback` to the last successful revision, producing yet another revision with the description
`Rollback to N`. Nothing is deleted, so the history tells the whole story: superseded, failed, deployed.
Because Deployments are applied before CronJobs, the Deployment may be changed and then restored
during that rollback.

## The fix
Read the failed revision's description, correct the schedule, and upgrade again. The new revision (4) is
`deployed` and contains the 0.5 changes.

## In real life
Atomic upgrades are the right default for pipelines: a half-applied release is worse than an old one.
The downside is observability: the job fails, the cluster looks healthy, and people inspect pods instead of
history. Make your pipeline print `helm history <rel> --max 5` when an upgrade fails, and alert on
`Rollback to` descriptions.

## Commands worth remembering
- `helm history <rel> --max 10` — status and description per revision
- `helm get manifest <rel> --revision 2` — what the failed revision tried to apply
- `helm upgrade --rollback-on-failure` (Helm 4) / `--atomic` (Helm 3)
- `helm template <rel> ./chart` — render and read the object that was rejected

## Common mistakes
- Assuming `deployed` means "my change is live" — check the chart version and the revision description.
- Re-running the same upgrade without changing anything.
- Looking only at pods: the failing object (a CronJob here) has no pods at all.

## Helm 3 vs Helm 4
`--atomic` was renamed `--rollback-on-failure` in Helm 4 (the old name remains as a deprecated alias on
some 4.x builds, so check `helm upgrade --help`). Both produce the same history: failed revision followed by
a `Rollback to N` revision. Helm 4 reports the API error from server-side apply in the description.
