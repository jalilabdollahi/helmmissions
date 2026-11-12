# Quota Says No

## What broke
The namespace has a ResourceQuota on cpu and memory requests and limits. The chart's `resources: {}` rendered a
container with no resources section, and the quota admission controller refuses to create any pod that does not declare
every quota-tracked resource: `failed quota: search-team-quota: must specify limits.cpu ...`. The Deployment was created,
the ReplicaSet was created, but the ReplicaSet could never create a pod.

## Why Helm behaves this way
`helm install` succeeds as soon as the API server accepts the Deployment object. The rejection happens later, when the
ReplicaSet controller tries to create pods, so Helm reports `deployed` and the error is only visible in the ReplicaSet's
events (`kubectl describe rs`, `kubectl get events`). `--wait` would have turned it into a timeout. Quota admission
needs explicit numbers: it adds up declared requests and limits against `hard`, so undeclared values cannot be
admitted. (A LimitRange with defaults would inject them automatically — a platform-side alternative.)

## The fix
Declare requests and limits for every container in the chart's values and make sure the sum for all replicas fits in
what is left of the quota, then upgrade. Never "solve" it by deleting or loosening the quota: it is how the platform team
protects the shared cluster.

## In real life
Quotas turn up when a team moves from a dev cluster to a shared one, and charts that defaulted resources to `{}` suddenly
stop scheduling silently. Rolling updates are another trap: surge pods count against the quota, so a quota that exactly
fits N replicas blocks every upgrade. Always run installs with `--wait`/`--timeout` in CI so the failure is loud, and
add `kubectl describe resourcequota` to your runbook.

## Commands worth remembering
- `kubectl describe resourcequota -n NS` — hard limits and current usage
- `kubectl describe rs -n NS` / `kubectl get events --sort-by=.lastTimestamp`
- `kubectl get limitrange -n NS` — defaults that may be injected for you
- `helm upgrade --install ... --wait --timeout 2m`

## Common mistakes
- Setting only requests (or only memory): the quota also tracks limits.
- Looking at `kubectl get pods` (empty) instead of the ReplicaSet events.
- Deleting or editing the quota instead of right-sizing the workload.
- Forgetting rolling-update surge: leave headroom for one extra pod.

## Helm 3 vs Helm 4
Same behaviour on both: the Deployment object is accepted, the quota rejection happens in the ReplicaSet controller. Use
`--wait` (Helm 3 and 4) so the pipeline fails instead of reporting `deployed`; on Helm 4 `--rollback-on-failure` replaces
`--atomic`.
