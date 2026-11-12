# Pending Forever

## What broke
Three releases failed for four different scheduling reasons, all visible only in the Pending pods' events. The ingest release
asked for `cpu: "500"` - a bare number is whole cores, so the pod wanted 500 CPUs (the author meant `500m`). The rollup release
asked for `2048Gi` of memory (Gi and Mi mixed up). The alerts release carried a `nodeSelector` for a node label that does not exist
in this cluster and, once that was fixed, a *required* pod anti-affinity that can never place two replicas on one node. Because the
old ReplicaSets were still serving, nothing went down: the new version just never arrived, and `helm upgrade --wait` reported the
timeout, leaving each release `failed`.

## Why Helm behaves this way
Helm renders and applies; the scheduler decides. Requests are quantities with Kubernetes suffixes (`m` for milli-CPU, `Mi`/`Gi`
for bytes), and the API server accepts any syntactically valid number, so absurd requests pass admission and only fail at scheduling
time. A Deployment's rolling update keeps the old pods until the new ones are ready, which hides the problem from users while
`--wait` turns it into a failed release. A failed release keeps its last good pods but is not `deployed` until a later upgrade succeeds.

## The fix
Read each Pending pod's `FailedScheduling` event, correct the quantities and scheduling constraints in the values files (within the
budget), and run the pipeline again. A normal `helm upgrade` from a `failed` release moves it forward.

## In real life
Units mistakes (`500` for `500m`, `Gi` for `Mi`) and scheduling constraints copied from big clusters (node selectors, hard
anti-affinity, topology spread) are among the most common reasons a "successful" pipeline never finishes a rollout. Add CI checks
for requests above the largest node, and prefer `preferred` anti-affinity or topology spread with `ScheduleAnyway` unless
you really need hard separation.

## Commands worth remembering
- `kubectl describe pod POD` (Events), `kubectl get events --sort-by=.lastTimestamp`
- `kubectl get nodes -o jsonpath='{.items[*].status.allocatable}'`, `kubectl describe node | grep -A8 Allocated`
- `kubectl get nodes --show-labels`
- `helm get values REL`, `helm history REL`
- `helm template ./chart -f values/x.yaml | grep -B2 -A4 resources:`

## Common mistakes
- Rolling back to make the alert go away: the pipeline then fails again on the next run and the new version is never released.
- Removing requests altogether: the pod schedules, but the platform loses its capacity guarantees.
- Patching Deployments live: the values files that the next release uses still contain the mistakes.

## Postmortem
Root causes: unit slips in values; a scheduling constraint for a label that exists only in another cluster; hard anti-affinity
on a small cluster. Contributing factors: the pipeline ran three releases but nobody read the `timed out` result; no policy check on requests.
Prevention: ResourceQuota / LimitRange to cap absurd requests, a values schema with units, `helm template | kubectl apply --dry-run=server`
in CI, and alerts on `FailedScheduling` events.

## Helm 3 vs Helm 4
No behavioural difference. `--wait` in Helm 4 is also based on resource readiness; the flags used here are identical.
