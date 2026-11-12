# The Migration Ran Too Late

## What broke
Chart 1.1.0 of `shipment-tracker` adds an init container that refuses to start until the schema marker for version 2
exists, and a Job that creates that marker. The Job was declared as a `post-upgrade` hook. With `helm upgrade --wait` Helm
applied the new Deployment, waited for the pods to become ready, and the pods waited for the schema. The upgrade timed out with
`context deadline exceeded`, was recorded as `failed`, and the post-upgrade hook never ran.

## Why Helm behaves this way
Hook phases are fixed points in the release lifecycle. `pre-upgrade` runs after templates are rendered but before any
resource is updated; `post-upgrade` runs after all resources are updated, and with `--wait` after they are ready. If the
operation fails (for example on the wait timeout), the post hooks are skipped. So any step the *new* workload needs in order
to start, such as schema migrations or seed data, belongs in `pre-upgrade`, while notifications, smoke tests and cache
warm-ups that need the new version running belong in `post-upgrade`.

## The fix
Switch the annotation to `pre-upgrade`. The Job then runs against the still-running old version, creates the marker, and the new
pods start cleanly. In real systems this is also why migrations have to be backward compatible with the old version, which
keeps serving traffic while the migration runs.

## In real life
The mistake is easy to make because the happy path hides it. Without `--wait`, a post-upgrade migration "works": pods crash a few
times, then recover after the hook finishes. Add `--wait` to CI (which you should) and the deadlock appears. Decide for each hook
whether the *new* version depends on its work (pre) or whether it depends on the new version (post).

## Commands worth remembering
- `helm upgrade --wait --timeout 2m` — surfaces the ordering problem as a deterministic failure
- `helm get hooks <release>` — which phase each hook is bound to
- `kubectl logs <pod> -c <init-container>` — why a pod is stuck in `Init:`
- `kubectl get jobs` — did the hook ever run?

## Common mistakes
- Creating the missing object by hand (`kubectl create configmap ...`): the upgrade works once, and breaks on a fresh environment.
- Removing `--wait` to make the pipeline green and letting pods crash-loop through the deploy.
- Assuming a failed upgrade still runs post-upgrade hooks. It does not.

## Helm 3 vs Helm 4
Same phase semantics in both. Helm 4 waits for hooks to finish by default even without `--wait` (`hookOnly`), but a
`post-upgrade` hook still only starts after the release resources have been applied, and, with `--wait`, are ready.
