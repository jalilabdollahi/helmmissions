# The Kept Secret

## What broke
Release `shop` was uninstalled, but `helm uninstall` deliberately leaves objects annotated with
`helm.sh/resource-policy: keep`. The Secret `db-credentials` therefore survived with the ownership annotations
`meta.helm.sh/release-name: shop`. The renamed chart `storefront` renders a Secret with the same name; Helm saw
that the existing object belongs to someone else and refused to install.

## Why Helm behaves this way
Helm tracks ownership in annotations on each object, not in a database: `meta.helm.sh/release-name`,
`meta.helm.sh/release-namespace` and the label `app.kubernetes.io/managed-by=Helm`. Before touching an
existing object, Helm verifies that the release name and namespace match the one being installed. The
`keep` policy exists to protect data (databases, PVCs, credentials) from `helm uninstall`; the price
is that the object becomes an orphan that still carries its old owner. Renaming a release is effectively
"uninstall + install under a new name", so orphans must be handed over explicitly.

## The fix
Either hand the object to the new release (`--take-ownership`, or edit the two annotations) or delete the
orphan when its content is recreated from the chart. If the data matters and the chart does not contain it,
hand over rather than delete.

## In real life
Renames happen on team re-orgs, namespace consolidations and when a chart gets a new name in a monorepo.
`keep` objects (PVCs, secrets, CRDs) are exactly the ones you can't afford to lose, so check them *before* the
uninstall: `helm get manifest <rel> | grep -B5 resource-policy`. Note that Helm never deletes a kept object
later, so you need to clean them manually when a release is truly retired.

## Commands worth remembering
- `kubectl get <kind> <name> -o jsonpath='{.metadata.annotations}'` — who owns it?
- `helm get manifest <rel> | grep -B8 'resource-policy'` — which objects survive an uninstall
- `helm install/upgrade --take-ownership` — adopt objects owned by another release or none
- `kubectl annotate --overwrite meta.helm.sh/release-name=<new>` — manual transfer

## Common mistakes
- Deleting the kept Secret or PVC before checking that its data can be recreated.
- Changing only `release-name` but not `release-namespace` when moving between namespaces.
- Dropping the object from the new chart: it then lives on unmanaged and unowned.

## Helm 3 vs Helm 4
`--take-ownership` exists on Helm 3.17+ and Helm 4. On Helm 4 the manual re-annotation recipe may additionally
hit server-side-apply field conflicts (the annotations were last set by another field manager) and need
`--force-conflicts`; `--take-ownership` did not in our tests because the previous manager was Helm itself.
