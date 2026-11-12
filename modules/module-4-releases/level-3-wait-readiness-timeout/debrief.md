# Timed Out Waiting

## What broke
Chart 2.1 added a readiness probe on `/healthz`, a path the stock nginx image answers with 404. The pod
runs, but Kubernetes never marks it Ready. The CI job ran `helm upgrade --wait --timeout 30s`, so Helm
waited the full timeout and then marked revision 2 as `failed` (`context deadline exceeded`).

## Why Helm behaves this way
Without `--wait`, Helm considers an upgrade done as soon as the API server accepted the manifests. With
`--wait`, Helm watches the workload until every Deployment/StatefulSet/Job reaches its desired state
(replicas Ready, Services with endpoints) or the timeout (default 5 minutes) expires. A timeout is not an
error in your chart's syntax; it is Helm telling you the rollout did not converge. The failed revision stays
in history, and because rolling updates keep the old pods until new ones become Ready, users usually still
see the previous version running.

## The fix
Fix the probe so it checks something the app really serves (`/`, a `/healthz` location in the nginx
config, or a TCP check), then upgrade again with `--wait`. Revision 3 becomes `deployed`.

## In real life
Readiness probes are the main reason `--wait` upgrades time out in CI: wrong path, wrong port,
authentication in front of the health endpoint, or a slow start that needs `startupProbe`. The
reflex of raising `--timeout` hides the problem; reading `kubectl describe pod` events shows the cause in
seconds. Removing the probe makes the pipeline green but sends traffic to pods that are not ready.

## Commands worth remembering
- `helm upgrade --wait --timeout 5m` — block until the rollout is healthy
- `kubectl describe pod <pod>` — probe failures are in Events
- `kubectl rollout status deploy/<name>` — watch the rollout directly
- `helm history <rel>` — the failure description is stored with the revision

## Common mistakes
- Increasing `--timeout` instead of finding out why a pod is not Ready.
- Rolling back and losing the other changes in the release.
- Deleting the probe to make the pipeline pass.

## Helm 3 vs Helm 4
Helm 4 waits with kstatus ("watcher" strategy) by default and prints the resource that is not ready
(`resource Deployment/ns/name not ready. status: InProgress`). Helm 3 prints only `timed out waiting for
the condition`. `--wait=legacy` selects the old polling behaviour on Helm 4.
