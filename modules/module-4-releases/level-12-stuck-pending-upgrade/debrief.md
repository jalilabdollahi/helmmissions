# Another Operation In Progress

## What broke
The Helm process that was upgrading `warehouse-stock` was killed (a CI runner OOM, a cancelled job, a laptop
closing mid-deploy). Helm had already written revision 2 with the status `pending-upgrade`. Nobody ever flipped
it to `deployed` or `failed`, so every later `helm upgrade` is refused with
`another operation (install/upgrade/rollback) is in progress`.

## Why Helm behaves this way
There is no lock service: the release Secret itself is the lock. At the start of an operation Helm writes the new
revision as `pending-install`, `pending-upgrade` or `pending-rollback`; at the end it updates it to its final
status. Helm refuses to start while the newest revision is pending, to avoid two clients mutating the same
release. A process killed between those two writes leaves the lock behind. `helm rollback` is allowed to run
anyway: it creates a new revision (`Rollback to N`) which becomes the newest, settled one, and the stale pending
revision stays in history as evidence. Deleting the pending revision's Secret is the manual alternative.

## The fix
First check that no Helm process or pipeline is still running. Then roll back to the last `deployed` revision and
repeat the upgrade you intended. Roll back alone leaves the release healthy but on the old version.

## In real life
Common triggers: CI job timeouts or cancellations during `--wait`, Spot runner reclaim, Ctrl-C at the wrong moment,
a `pre-upgrade` hook that hangs. Use `--timeout` and `--atomic`/`--rollback-on-failure` so Helm cleans up after
itself, make pipelines uncancellable at deploy time, and monitor `helm list --pending`.

## Commands worth remembering
- `helm list --pending -n <ns>` — releases with an unfinished operation
- `helm history <rel>` — find the pending revision
- `helm rollback <rel> <last-good>` — settle the release
- `kubectl get secret -l owner=helm,name=<rel>` — the raw revision records

## Common mistakes
- Deleting pods or restarting the pipeline: the lock is in the release record, not in the workload.
- Removing the wrong Secret (the deployed revision) and orphaning the release.
- Rolling back and forgetting the interrupted upgrade, leaving production on the old version.

## Helm 3 vs Helm 4
Same state machine and same error message on both. On Helm 4 `helm list` has no `-a`; use `--pending` (or
`helm history`) to see unfinished operations.
