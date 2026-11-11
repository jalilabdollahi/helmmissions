# The Good Revision Is Gone

## What broke
The pipeline deploys with `--history-max 3`. Every upgrade beyond the third deletes the oldest revision
Secret, so when the provider migration went wrong in three consecutive upgrades, revision 1 - the last
good one - was pruned. `helm rollback geo-lookup 1` fails because there is nothing left to roll back to,
and revisions 2-4 are all broken.

## Why Helm behaves this way
Each revision is stored as a Secret (or ConfigMap) in the release's namespace. Helm keeps at most
`--history-max` of them (default 10 in Helm 3 and 4; 0 means unlimited) and deletes the oldest after each
upgrade. History is a bounded undo buffer, not an archive. When the buffer holds only bad revisions, the
only path is forward: build the good configuration from the source of truth (the chart plus values files in
Git) and deploy it as a new revision. Chart defaults are the most reliable reference - they are
versioned with the chart.

## The fix
Reset `values-prod.yaml` to what you know is good (here: remove the leftover overrides), then deploy with the
pipeline script. Do not use `--reuse-values`: it would carry the bad overrides into the new revision.

## In real life
Small `--history-max` values are popular because each revision of a big chart is a large Secret (and
etcd objects have a 1 MiB limit). But rapid-fire fixes during an incident burn through the buffer - teams
discover it exactly when they need the old revision. Keep a sensible window (10-20), store the values files
in Git so every deploy is reproducible, and use `helm get values <rel> --revision N -o yaml > file` to snapshot
a known-good configuration before experimenting.

## Commands worth remembering
- `helm history <rel> --max 50` - what is still stored
- `helm upgrade --install ... --history-max 20` - size of the undo buffer
- `helm get values <rel> --revision N -o yaml > good.yaml` - snapshot a revision's values
- `helm upgrade ... --reset-values -f values-prod.yaml` - rebuild values from files only

## Common mistakes
- Rolling back to the oldest revision that remains without checking it - it may be broken too.
- Using `--reuse-values` while fixing forward: bad `--set` overrides survive.
- Assuming history is permanent and not recording good values anywhere else.

## Helm 3 vs Helm 4
Same pruning behaviour and the same default of 10. In Helm 4 a plain `helm upgrade` with no values reuses the
previous release's user values, while `-f`/`--set` replace them - spell out `--reset-values` or
`--reuse-values` in pipelines to avoid surprises.
