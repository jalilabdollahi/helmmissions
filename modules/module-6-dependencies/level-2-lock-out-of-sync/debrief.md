# Chart.lock Out Of Sync

## What broke
`ledger/Chart.yaml` was changed to require `ledger-db` 0.4.0, but nobody regenerated `Chart.lock`, which still
recorded 0.3.0, and `charts/` still held `ledger-db-0.3.0.tgz`. The CI step `helm dependency build` compares a digest
of the dependency declarations in `Chart.yaml` with the digest stored in `Chart.lock` and aborts when they differ.

## Why Helm behaves this way
`Chart.lock` is the equivalent of `package-lock.json`: `update` resolves version constraints and writes the exact versions
and a digest; `build` is the reproducible half and downloads strictly what the lock says. If `Chart.yaml` changed
after the lock was written, `build` refuses instead of silently building something nobody reviewed.
Note what does *not* check anything: `helm install` and `helm upgrade` only verify that a subchart of the declared
*name* exists in `charts/`. They never compare its version with `Chart.yaml`. So the "quick" path, upgrading without a
dependency step, succeeds and quietly redeploys the old 0.3.0 database.

## The fix
`helm dependency update ./ledger` rewrites the lock and swaps the tarball. Then `helm dependency build` passes and
`helm upgrade` ships ledger-db 0.4.0. Commit the new `Chart.lock` with the `Chart.yaml` change in the same commit.

## In real life
Stale locks are the most common dependency incident: a constraint is edited in a pull request, the lock is not,
and either CI fails (good) or, when CI only runs `helm upgrade`, the old subchart keeps shipping (bad, and invisible).
Run `helm dependency build` in CI, review lock changes like code, and make a check that fails when `helm dependency update`
would change `Chart.lock`.

## Commands worth remembering
- `helm dependency list ./chart` — compare declared versus present
- `helm dependency update ./chart` — resolve again, rewrite `Chart.lock`
- `helm dependency build ./chart` — reproduce from the lock, fail when it is stale
- `kubectl get deploy -L helm.sh/chart` — which chart version a workload really came from

## Common mistakes
- Editing the version in `Chart.lock` by hand: the digest no longer matches, `build` still refuses.
- Upgrading without a dependency step: it works, and deploys the previous subchart version.
- Deleting `Chart.lock` and committing no replacement: builds stay unreproducible.

## Helm 3 vs Helm 4
No difference in the error text or the digest check. In both versions the install/upgrade path does not verify subchart versions.
