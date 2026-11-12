# Unable To Build Kubernetes Objects

## What broke
`helm upgrade` and `helm rollback` both start by building Kubernetes objects from the manifest stored in the release's current revision,
so Helm can compute what to change or delete. That stored manifest named `policy/v1beta1` and `autoscaling/v2beta1` objects, API
versions the cluster has since stopped serving, so Helm failed before it touched anything. Fixing the record then exposed the next layers: the chart in
the workspace still rendered the removed versions (and an HPA layout that only existed in the old API), and its autoscaling values had the minimum above the maximum.

## Why Helm behaves this way
A release record is a Secret (type `helm.sh/release.v1`) whose `release` key holds gzip-compressed JSON, base64-encoded by Helm and
then again by Kubernetes. It is a snapshot: it is not converted when the cluster's API versions change, and Helm needs a REST mapping for every
object in it. The live objects are served through the new version, so the cluster works, while the history is unusable until the record is
migrated. The `helm-mapkubeapis` plugin does exactly this: it rewrites old apiVersions in stored manifests.

## The fix
Patch the current revision's record (decode, replace the removed apiVersions, re-encode, patch the Secret), update the chart to the served API
versions with their new schemas, correct the values, and run a normal upgrade so history and live objects are kept.

## In real life
Kubernetes upgrades regularly remove API versions. Teams that skip the "update charts and migrate release records first" step meet this
error during an unrelated deploy, often at the worst moment. Run `kubectl api-resources`/pluto-style scans against rendered charts *and* stored releases before a cluster upgrade,
and keep backups of release Secrets (`kubectl get secret -l owner=helm -o yaml`) before editing them.

## Commands worth remembering
- `helm get manifest REL | grep apiVersion`, `helm history REL`
- `kubectl get secret -l owner=helm,name=REL -n NS`
- `kubectl api-versions`, `kubectl explain hpa.spec.metrics.resource.target`
- `helm upgrade REL ./chart --dry-run` to reproduce the build error without side effects
- `helm plugin install https://github.com/helm/helm-mapkubeapis` (when you have network access)

## Common mistakes
- Uninstalling and reinstalling the release: it recreates the gateway (downtime) and loses the history the on-call depends on.
- Trying `helm rollback` first: it builds from the same broken record, fails, and leaves a `pending-rollback` revision that blocks every later operation until its Secret is deleted.
- Patching only the chart; the stored record still breaks every upgrade and rollback.
- Editing a release Secret without keeping a copy of the original.

## Postmortem
Root causes: a release record and a chart that were never migrated off removed API versions before the cluster upgrade; autoscaling values with min above max.
Contributing factors: nobody deployed the gateway between the cluster upgrade and the change window; no API deprecation scan covered stored releases.
Prevention: scan rendered manifests and stored releases for deprecated APIs ahead of every cluster upgrade, run `mapkubeapis` as part of the upgrade runbook,
deploy something small regularly so rot shows up early, and validate HPA values in CI.

## Helm 3 vs Helm 4
The storage format is the same on both (`helm.sh/release.v1`, gzip + base64 JSON); Helm 4 records add an `apply_method` field. The error text is
identical. Helm 4's server-side apply does not change this: it still needs REST mappings for the objects of the previous manifest.
