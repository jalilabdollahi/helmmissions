# Field Is Immutable

## What broke
Chart 1.1 refactored the label helpers so that the Deployment's `spec.selector` became
`app.kubernetes.io/name` + `app.kubernetes.io/instance`. The running Deployment, created by 1.0, selects on
`app: catalog-search`. Kubernetes does not allow a Deployment's selector to change, so revision 2 failed.

## Why Helm behaves this way
Helm does not know which fields are mutable; it renders, sends the objects to the API server and reports what
comes back. The selector of Deployments, StatefulSets and DaemonSets (and `clusterIP`, Job pod templates,
`volumeClaimTemplates`) are immutable by design: the ReplicaSets and pods already created are tied to them.
The failed upgrade is recorded as a `failed` revision and the old pods keep running.

## The fix
Selector labels must stay frozen for the life of the object. Keep a dedicated helper for them that never
changes, and put any new labels in the pod template/metadata only. Upgrade; the pod template change rolls
pods, the selector stays as it was, and history is preserved.

## In real life
Label "modernisation" PRs and `helm create` scaffolds are the usual cause. The ugly fix, uninstall and
reinstall, means downtime and loss of history; if a selector truly must change, plan a migration (second
Deployment, switch the Service, delete the old one) or use `--force-replace`, which deletes and recreates
the object and accepts a short outage.

## Commands worth remembering
- `kubectl get deploy <name> -o jsonpath='{.spec.selector}'` — what the live object selects
- `helm template <rel> ./chart` — what the new revision will send
- `helm get manifest <rel> --revision N` — what an old revision sent
- `helm upgrade --force-replace` (Helm 4) / `--force` (Helm 3) — delete and recreate when a field is immutable

## Common mistakes
- Using one helper for both selector and metadata labels, then adding to it.
- Reaching for uninstall/reinstall and losing release history and availability.
- Adding `app.kubernetes.io/version` (changes every release) to a selector.

## Helm 3 vs Helm 4
Same lesson on both. The error text on Helm 4 starts with `server-side apply failed for object ...`, on Helm 3
it is `cannot patch "catalog-search" with kind Deployment: ... field is immutable`. The force flag is
`--force-replace` on Helm 4 and `--force` on Helm 3.
