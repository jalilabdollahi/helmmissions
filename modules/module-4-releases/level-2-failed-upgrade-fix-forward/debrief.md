# Fix Forward

## What broke
Chart 1.1 of `ledger-sync` contained a readinessProbe with two handlers (`httpGet` and `tcpSocket`).
The API server rejected the Deployment, so revision 2 was recorded as `failed` while the pods from
revision 1 kept running.

## Why Helm behaves this way
A failed upgrade does not undo anything by itself. Revision 1 keeps serving (its Secret still says
`deployed` in the history until a newer revision succeeds) and revision 2 is written with status
`failed` and the error as its description. `helm status` reports the *latest* revision, so the release
looks failed even though production is running the old version. You then have two ways out:
`helm rollback` creates a new revision that is a copy of an old one (the new feature disappears), or you
fix the chart and run `helm upgrade` again, creating revision 3 from the corrected chart. Either way
the history only grows: the failed revision remains as evidence.

## The fix
Remove the extra probe handler and upgrade. Revision 1 becomes `superseded`, revision 2 stays `failed`,
revision 3 is `deployed` and carries the 1.1 settings.

## In real life
The reflex "something failed, roll it back" is often wrong. When the failed upgrade delivers a feature
or a schema-dependent config that other teams already rely on, rolling back trades a deploy error for
a functional regression. Fixing forward is also the only option once the old revision has been pruned by
`--history-max`. Rollback is the right tool when the new version runs but misbehaves.

## Commands worth remembering
- `helm history <rel>` — every revision with status and error description
- `helm get values <rel> --revision N` / `helm get manifest <rel> --revision N` — what a revision contained
- `helm upgrade --install --wait` — deploy and wait for readiness
- `helm install --dry-run=server` / `helm template --validate` — catch API-level errors before deploying

## Common mistakes
- Running `helm rollback` on reflex and losing the intent of the change.
- Fixing the chart files but forgetting to run the upgrade.
- Patching the Deployment with kubectl: the release stays `failed` and the next upgrade overwrites it.

## Helm 3 vs Helm 4
Both keep the failed revision. Helm 4's server-side apply makes the API server's field-level message
(`...may not specify more than 1 handler type`) the revision description, which makes `helm history`
even more useful for diagnosis.
