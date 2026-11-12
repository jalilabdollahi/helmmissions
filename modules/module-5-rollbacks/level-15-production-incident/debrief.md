# Incident: Checkout Is Down

## What broke
Three independent problems stacked up. Revision 2 switched the payment provider to a gateway that had been
retired. During that outage the on-call engineer forced a fallback mode with `kubectl set env`, a change that lives
only in the cluster. Revision 3 then shipped a payment timeout of 300 ms from `values-prod.yaml`. The reflexive
"roll back one revision" lands on revision 2 - also broken - and even the right rollback would have left the manual
`FORCE_FALLBACK` variable behind, because it is in no revision.

## Why Helm behaves this way
A rollback is an upgrade whose inputs are an old revision's manifest and values: it patches the live objects
towards that manifest. Fields that exist only in the cluster (added with kubectl) belong to no revision, so
neither the three-way merge nor server-side apply removes them. Equally, a rollback restores the *cluster*, not
the Git repository: the pipeline still deploys `values-prod.yaml` with the bad timeout on its next run, undoing the
rollback silently. Recovering from an incident means fixing three layers - the revision, the live drift and the
source of truth.

## The fix
Identify the last revision that was actually good (revision 1) with `helm get values --revision`, roll back (or
fix forward), delete the manual hotfix variable, correct `values-prod.yaml`, and redeploy through the pipeline so
the cluster, the release record and Git agree.

## In real life
Incident reviews keep finding the same pattern: the rollback "worked", then the Monday pipeline run
re-introduced the bug, or a forgotten `kubectl set env` kept production in a degraded mode for weeks. Practical
rules: never trust "previous revision" blindly, record every manual change in the incident timeline and
revert it before closing, and finish with a deploy from Git so the release history shows the real state.

## Commands worth remembering
- `helm history <rel>`, `helm get values <rel> --revision N` - find the last good revision
- `helm get manifest <rel>` vs `kubectl get deploy <name> -o yaml` - find drift
- `kubectl set env deployment/<name> VAR-` - remove a manual variable
- `helm rollback <rel> N --wait` - restore a revision and verify it
- `helm template ./chart -f values-prod.yaml` - preview what the pipeline will deploy

## Common mistakes
- Rolling back to the previous revision without testing it.
- Declaring victory after the rollback while the pipeline's values still contain the bug.
- Leaving incident hotfixes in the cluster after the incident.

## Helm 3 vs Helm 4
The behaviour is the same on both. Helm 4's server-side apply additionally refuses to overwrite fields owned by
another manager (such as a hand-edited env value) with a conflict error, which can make drift visible earlier.
