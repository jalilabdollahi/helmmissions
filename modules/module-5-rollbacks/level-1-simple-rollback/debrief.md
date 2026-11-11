# Roll It Back

## What broke
`quotes-api` revision 2 referenced an image tag that was never published. Helm applied the manifest
without complaint, so the release is `deployed` - but the new pod can never pull its image, and because
the Deployment uses the `Recreate` strategy the old, working pod was already gone.

## Why Helm behaves this way
Helm stores every revision of a release as a Secret (`sh.helm.release.v1.<name>.v<N>`) containing the
rendered manifest, the chart, and the user-supplied values. Without `--wait` (or `--rollback-on-failure`)
Helm only checks that the API server accepted the objects - not that pods become Ready. `helm rollback`
does not "undo" anything: it takes the manifest and values of an older revision and installs them as a
brand-new revision (3, "Rollback to 1"). History only ever grows.

## The fix
`helm rollback quotes-api 1 -n helmissions --wait` - no chart source needed, because revision 1's manifest
is already stored in the cluster. Use `helm history` first to pick the right revision.

## In real life
Rollback is the fastest mitigation for a bad deploy: seconds, no CI pipeline, no code review. Teams
usually roll back first and diagnose afterwards. The catch is that a rollback is a normal change - it
needs the same `--wait --timeout` discipline, and the next pipeline run will happily redeploy the bad
version unless the source of the problem is fixed or the pipeline is paused.

## Commands worth remembering
- `helm history <rel> -n <ns>` - list revisions, statuses and descriptions
- `helm get values <rel> --revision N` / `helm get manifest <rel> --revision N` - inspect an old revision
- `helm rollback <rel> [N] --wait --timeout 2m` - go back (omit N for "the previous revision")
- `helm status <rel>` - current state

## Common mistakes
- Trusting `STATUS: deployed` as proof the app works; deploy with `--wait` so failures are visible.
- Running `helm rollback` without a revision number when the previous revision is also bad.
- Fixing forward with a hurried upgrade when a known-good revision is one command away.

## Helm 3 vs Helm 4
Identical for this level. Helm 4 can also roll back automatically on a failed upgrade with
`--rollback-on-failure` (Helm 3: `--atomic`).
