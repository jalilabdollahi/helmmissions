# Hook Job Already Exists

## What broke
`tax-engine` runs a rate-table check as a `pre-install,pre-upgrade` hook Job named `<release>-rate-check`. Its
`hook-delete-policy` was `hook-failed`, chosen so successful runs stay around for the auditors. After the first install the
completed Job was still in the namespace. The next upgrade rendered a Job with the same name and a different pod template (it
carries the release revision), and the API server refused it: `field is immutable` on current Helm, or
`jobs.batch "tax-engine-rate-check" already exists` on older ones. The upgrade failed before the Deployment was touched.

## Why Helm behaves this way
Hook resources are created by Helm at a lifecycle phase but are *not* part of the stored release manifest, so Helm never
reconciles or garbage-collects them like normal resources. What happens to them is decided only by `helm.sh/hook-delete-policy`:
`before-hook-creation` (delete the previous instance before creating the new one), `hook-succeeded` and `hook-failed`
(delete after the outcome). With **no** policy at all, Helm uses `before-hook-creation`, so this bug appears only when someone
sets an explicit policy that leaves a finished Job behind. Since Job pod templates are immutable, a leftover Job can never be updated in place.

## The fix
Include `before-hook-creation` in the policy (alone or together with `hook-failed`). Helm then deletes the
previous Job right before creating the next, so there is always at most one, the latest run is inspectable with `kubectl logs`,
and no collision can occur. `hook-succeeded,hook-failed` also works if you do not need to keep logs.

## In real life
This is one of the most common hook failures in CI: the first deploy is green, the second one is red, and the only
"fix" anyone remembers is `kubectl delete job`, which holds for exactly one deploy. Always set a delete policy
explicitly when you set one at all, and remember to include `before-hook-creation`. Also set `ttlSecondsAfterFinished`
if you want Kubernetes itself to clean up old Jobs.

## Commands worth remembering
- `helm get hooks <release>` — shows the hook annotations that are actually stored
- `kubectl get jobs` / `kubectl logs job/<name>` — leftover hook Jobs and their output
- `helm history <release>` — a failed hook shows up as a failed revision

## Common mistakes
- Deleting the Job by hand and re-running the upgrade: works once, breaks the next deploy.
- Using `--no-hooks` to push past the error: the check silently stops running.
- Putting a unique suffix on the Job name to avoid the collision, which leaves an ever-growing pile of Jobs.

## Helm 3 vs Helm 4
In Helm 3 a leftover hook Job always fails with `already exists` when no delete policy removes it. Helm 4 applies hooks
with server-side apply by default: an identical leftover Job is silently reused (the hook does not run again!), and a changed
Job fails with `field is immutable`. With no policy set, both versions default to `before-hook-creation`.
