# The Invisible Release

## What broke
The release was written by a CI job that exports `HELM_DRIVER=configmap`. Helm keeps release state in
whichever storage backend the `HELM_DRIVER` variable selects - Secrets by default - and every command only
looks there. From a terminal without that variable, `helm list` sees no releases at all even though the
workload is running and its objects carry Helm's labels. The pod was crash-looping because revision 2
passed an unknown flag to the container.

## Why Helm behaves this way
A release is just data: one record per revision, stored as a Secret (`sh.helm.release.v1.<name>.v<N>`),
a ConfigMap with the same name pattern, or in an SQL database. The default of Secrets exists because
release data can contain values; ConfigMaps are readable by anyone with ConfigMap access. Helm has no
registry of "which driver did you use": you must tell it each time. Ownership labels on objects
(`app.kubernetes.io/managed-by: Helm`, `meta.helm.sh/release-name`) say that *a* release owns them, not where
its record is.

## The fix
`export HELM_DRIVER=configmap`, then `helm history` / `helm rollback audit-gateway 1`. A fresh `helm install`
without the variable creates a second, unrelated release in Secrets and leaves the real release's history
untouched - the pipeline will keep fighting with it.

## In real life
Mixed drivers show up when one pipeline uses `HELM_DRIVER=configmap` (or `sql`) and engineers use the default,
or after migrating from Helm 2 (where release records were ConfigMaps in kube-system). The symptom - "helm
list is empty but Helm labels are everywhere" - sends people on long hunts. Document the driver, export it in
the shared shell profile or wrapper, and look for `sh.helm.release.v1.*` objects when a release goes missing.

## Commands worth remembering
- `kubectl get secrets,configmaps -n <ns> -l owner=helm` - find release records of either type
- `HELM_DRIVER=configmap helm list -A` - list releases stored as ConfigMaps
- `helm env | grep HELM_DRIVER` - what the current shell uses
- `kubectl get cm sh.helm.release.v1.<rel>.v<N> -o yaml` - the raw record (labels show status and version)

## Common mistakes
- Reinstalling under the default driver and ending up with two competing releases.
- Setting `HELM_DRIVER` for the first command and forgetting it for the rollback.
- Editing the live Deployment with kubectl: Helm's record is unchanged and the next deploy reverts it.

## Helm 3 vs Helm 4
Both support `secrets`, `configmap`, `memory` and `sql` drivers selected with `HELM_DRIVER`. The behaviour
described here is identical.
