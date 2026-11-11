# Rolled Back But Still Broken

## What broke
The rollback worked exactly as designed: it restored revision 1's manifest, including the ConfigMap with
`RATE_LIMIT: "100"`. But the pods consume that ConfigMap through `envFrom`, and environment variables are
read once, when a container starts. The Deployment's pod template was identical before and after the
rollback, so Kubernetes had no reason to replace the pods that were still running with `rateLimit: 1`.

## Why Helm behaves this way
Helm applies manifests; it does not know which pods depend on which ConfigMap. A Deployment rolls its pods
only when `spec.template` changes. Mounted ConfigMap volumes eventually refresh in place, but env vars never
do. The standard answer is the checksum pattern: put a hash of the rendered ConfigMap (or Secret) in a pod
annotation. When the config changes, the hash changes, the template changes, and the Deployment rolls - on
upgrade and on rollback alike, because a rollback restores the old template *and* the old annotation.

## The fix
Add `checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}` under the
pod template's annotations and run `helm upgrade`. The very first upgrade restarts the pods because the
annotation is new.

## In real life
"We rolled back and it's still broken" is one of the most demoralising incidents: the revision history
looks right while the pods run yesterday's config. It is also invisible in `helm status`. Charts that read
configuration from ConfigMaps/Secrets should always carry the checksum annotation (it is in `helm create`
based chart guides for a reason), or use a reloader operator.

## Commands worth remembering
- `kubectl exec deploy/<name> -- env` - what the running container actually sees
- `kubectl rollout restart deployment/<name>` - emergency restart (does not fix the chart)
- `kubectl rollout history deployment/<name>` - Deployment-level revisions, separate from Helm's
- `helm template ./chart --set rateLimit=1 | grep checksum` - verify the hash changes with config

## Common mistakes
- Fixing it with `kubectl rollout restart` and moving on - the next rollback will repeat the incident.
- Upgrading the unchanged chart: the template is the same, so nothing restarts.
- Hashing the wrong thing (a template that is not the one containing the data).

## Helm 3 vs Helm 4
Identical. The checksum annotation is a chart pattern, not a Helm feature, and works with both.
