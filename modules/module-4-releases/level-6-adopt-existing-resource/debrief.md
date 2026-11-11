# Invalid Ownership Metadata

## What broke
The chart declares a ConfigMap named `desk-settings`, but an object with that name already existed in
the namespace, created by `kubectl create`. Helm refused to install: it will never silently overwrite an
object that does not belong to the release.

## Why Helm behaves this way
Helm records ownership on every object it creates with the label `app.kubernetes.io/managed-by: Helm`
and the annotations `meta.helm.sh/release-name` and `meta.helm.sh/release-namespace`. Before an
install or upgrade Helm checks existing objects of the same kind and name: if the metadata is missing or
names another release, it aborts with `invalid ownership metadata` and lists exactly which label or
annotation is wrong. This protects objects that belong to another release or to another team.
Since Helm 3.17/4.0 `--take-ownership` skips that check and adopts the object. On Helm 4, new
releases are applied with server-side apply, so Kubernetes also tracks *field managers*: the
fields `kubectl` set are owned by `kubectl-create`, and Helm gets `conflict with "kubectl-create"` unless
you pass `--force-conflicts` (or use `--server-side=false`).

## The fix
Either remove the old object so Helm creates it, or make Helm the owner: `helm install ... --take-ownership
--force-conflicts` (Helm 4) which also makes the chart's values win. Adding the annotations by hand is the
classic recipe, but on Helm 4 it still needs a client-side install.

## In real life
This appears when a platform team migrates hand-made or kustomize-made objects into a chart, when two charts
want the same object (shared ConfigMap, Namespace, ServiceAccount) and when someone `kubectl apply`s a
hotfix and later wants Helm to manage it. Decide who is the source of truth, then adopt or delete.

## Commands worth remembering
- `kubectl get <kind> <name> -o yaml` — look for `meta.helm.sh/*` and `managed-by`
- `helm install/upgrade --take-ownership` — adopt unowned objects (and take them from other releases)
- `kubectl get <kind> <name> --show-managed-fields -o yaml` — see which field manager owns which field
- `helm get manifest <rel>` — what the release believes it manages

## Common mistakes
- Adding only one of the three ownership markers, or the wrong release name or namespace.
- Using `--take-ownership` and assuming the data is overwritten: on Helm 4 fields keep their previous
  owner until `--force-conflicts` is given, and keys the chart does not define (`LEGACY_QUEUE`) survive.
- Deleting a ConfigMap that something else still depends on without checking.

## Helm 3 vs Helm 4
Helm 3 (client-side apply) checks the ownership metadata and then patches the object; adoption by annotating
works. Helm 4 defaults to server-side apply for new releases: the annotate-and-install recipe still fails with
a field-manager conflict unless you add `--server-side=false` or `--force-conflicts`. `--take-ownership` exists
on Helm 3.17+ and 4.
