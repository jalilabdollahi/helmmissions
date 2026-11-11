# Pre-rollback Hook Says No

## What broke
The chart declares a `pre-rollback` hook Job that drains a queue through a `queue-admin` service. That service
was decommissioned, so the hook fails every time. Helm runs `pre-rollback` hooks first and aborts the
rollback if one fails - so at the exact moment the team needed the safety net, it refused to open. Each failed
attempt also leaves a `pending-rollback` revision in the history.

## Why Helm behaves this way
Hooks are Helm's extension points: `pre-install`, `post-upgrade`, `pre-rollback`, `post-rollback`, `pre-delete`
and so on. A hook that fails fails the operation; that is the point (a failed DB migration must block the
upgrade). Rollback hooks come from the *target* revision's manifest, so a hook that existed when revision 1 was
deployed runs again when you go back to it. Helm marks hook resources as hooks, not as release resources:
they are not part of `helm get manifest` and are not deleted with the release unless a delete policy says so.
`--no-hooks` skips them for one command, which is why it is the emergency exit when a hook is the thing that is broken.

## The fix
`helm rollback settlement-batch 1 --no-hooks --wait`. An upgrade is not an escape route: the failed rollback
leaves the newest revision in `pending-rollback`, and Helm refuses new upgrades with "another operation
(install/upgrade/rollback) is in progress" - only a successful rollback clears the state. Afterwards repair or
remove the dead hook.

## In real life
Rollback hooks rot because nobody exercises them: the service they call is renamed, a Secret is rotated, the
image they use is deleted. Treat rollback paths like backups - test them. Keep hooks idempotent and tolerant
(`|| true` for best-effort steps), give them `activeDeadlineSeconds`, and use `hook-delete-policy:
before-hook-creation` so retries are not blocked by leftovers.

## Commands worth remembering
- `helm get hooks <rel>` - list hook manifests
- `helm rollback <rel> N --no-hooks` / `helm upgrade --no-hooks` - skip hooks for this operation
- `kubectl logs job/<hook-job>` - why the hook failed
- `helm history <rel>` - spot stale `pending-rollback` revisions

## Common mistakes
- Retrying the same rollback repeatedly: it fails the same way and adds more stale revisions.
- Hand-patching the Deployment and leaving the release in a half-finished state.
- Disabling hooks permanently instead of fixing the dead hook afterwards.

## Helm 3 vs Helm 4
Same hook semantics. A failed pre-rollback hook leaves a `pending-rollback` revision behind in both
versions; `--no-hooks` is available on `install`, `upgrade`, `rollback` and `uninstall`.
