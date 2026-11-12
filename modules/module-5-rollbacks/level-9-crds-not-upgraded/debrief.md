# The CRD That Never Updated

## What broke
Chart 2.0.0 extended the `SnapshotPolicy` CRD and used the new field in a custom resource. But the CRD
lives in the chart's `crds/` directory, and Helm only installs that directory on `helm install`. The cluster
kept the 1.0.0 schema, so the API server refused a `SnapshotPolicy` with a field it does not know and the
upgrade was recorded as `failed`.

## Why Helm behaves this way
CRDs are cluster-scoped, shared and dangerous: deleting or changing one affects every custom resource of
that kind in every namespace, possibly owned by other teams. Helm's maintainers therefore chose a
deliberately limited contract: files in `crds/` are created if missing, are never templated, never upgraded
and never deleted by `helm upgrade`, `rollback` or `uninstall`. (Putting the CRD in `templates/` gives you
upgrades but breaks first installs of CRs in the same chart, and deletes the CRD on uninstall.) CRD
lifecycle is the chart user's job.

## The fix
Apply the new CRD yourself - `kubectl apply -f snapshot-scheduler/crds/` - and then upgrade the release. Order
matters: CRD first, custom resources second. With Helm 4's server-side apply the repeated upgrade also
writes the new field to the existing custom resource.

## In real life
This is the standard CRD gotcha for operators (cert-manager, Prometheus operator, Argo...). Mature teams ship
CRDs as a separate chart or a separate pipeline stage (`kubectl apply --server-side -f crds/`), pin the CRD
version next to the operator version, and add a pre-upgrade CI check that diffs `crds/` against the cluster.

## Commands worth remembering
- `kubectl apply --server-side -f chart/crds/` - update CRDs (server-side avoids annotation size limits)
- `kubectl get crd <name> -o yaml` - the schema the cluster actually has
- `helm show crds ./chart` - print the chart's crds/ content
- `helm upgrade --skip-crds` / `helm install --skip-crds` - never touch crds/ at install

## Common mistakes
- Assuming `helm upgrade` updates `crds/` - it never does.
- Deleting the field from the custom resource so the upgrade passes, silently dropping the new feature.
- Deleting and recreating the CRD: that deletes every existing custom resource of that kind.

## Helm 3 vs Helm 4
Same `crds/` contract in both. The error text differs: Helm 4's server-side apply reports `field not declared
in schema`; Helm 3's client-side apply typically reports `unknown field "retentionDays"` from validation.
