# Cannot Re-use a Name

## What broke
`helm install orders ./orders` tried to create a second release called `orders` in a namespace where one
already existed. Helm refuses: a release name is unique per namespace, and the existing release owns the
Deployment, Service and history behind that name.

## Why Helm behaves this way
Helm distinguishes *creating* a release (`install`) from *changing* one (`upgrade`). The release record
(a Secret named `sh.helm.release.v1.orders.v<N>` by default) holds every revision: chart, values and
manifest. `upgrade` appends a revision and computes a diff against the previous one, so it can update
only what changed and so `helm rollback` can go back. `install` on an existing name would have to
overwrite that record, so Helm stops instead.

## The fix
Use `helm upgrade orders ./orders`. Revision 1 stays as `superseded`, revision 2 becomes `deployed`.
In pipelines prefer `helm upgrade --install`: it installs when the release is absent and upgrades when it
exists, so the same command serves first deploy and every later one.

## In real life
The tempting shortcut is `helm uninstall` followed by `helm install`. That causes downtime (everything is
deleted, then recreated), wipes the history (no rollback), runs delete hooks and may remove resources
such as PVCs. Reserve it for releases that are truly broken beyond upgrade - and even then look at
`--keep-history` first.

## Commands worth remembering
- `helm list -n <ns>` - which releases exist (use `-A` for all namespaces)
- `helm history <rel> -n <ns>` - revisions with chart versions and status
- `helm upgrade <rel> ./chart -n <ns> --wait`
- `helm upgrade --install <rel> ./chart` - idempotent deploy
- `helm diff upgrade` (plugin) - preview what an upgrade changes

## Common mistakes
- Uninstalling to "get a clean install" and losing the history.
- Forgetting `-n`: Helm looks in the current namespace only and reports the release as missing.
- Running `helm upgrade` for a release that was never installed (use `--install`).

## Helm 3 vs Helm 4
Same rule. The message is spelled "cannot re-use a name that is still in use" in Helm 3 and
"cannot reuse a name that is still in use" in Helm 4 (wrapped in "release name check failed").
