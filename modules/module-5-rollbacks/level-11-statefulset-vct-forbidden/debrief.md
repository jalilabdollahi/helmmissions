# Forbidden: StatefulSet Spec

## What broke
Chart 1.1.0 changed two things in the StatefulSet: the pod template (new retention setting - allowed) and
`volumeClaimTemplates` (storage 1Gi to 2Gi - forbidden). The API server validates the whole object, so the
single illegal field makes the entire upgrade fail and revision 2 is recorded as `failed`; nothing from the
release is applied.

## Why Helm behaves this way
Helm only sends the new manifest; Kubernetes decides what can change. For a StatefulSet, everything except
`replicas`, `template`, `updateStrategy`, `persistentVolumeClaimRetentionPolicy`, `minReadySeconds` and
`ordinals` is immutable. `volumeClaimTemplates` are used once per pod, when its PVC is first created; changing the
template later could never resize or alter the PVCs that already exist, so Kubernetes rejects it rather than
pretend. Neither Helm's three-way merge nor server-side apply can override that - `--force-replace` would
delete and recreate the object and put the data at risk.

## The fix
Separate the changes. Keep the retention bump and restore the original volume request in the chart (values or
template), then upgrade. If you really need more space, expand the existing PVCs (`kubectl patch pvc
data-tsdb-0 -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'` on a StorageClass with
`allowVolumeExpansion`), or delete the StatefulSet with `--cascade=orphan` and recreate it with the new
template in a maintenance window.

## In real life
Capacity changes to StatefulSet-backed databases are a frequent upgrade failure: a values bump by someone who
does not know the object is immutable. CI can catch it with `helm template | kubectl diff` (or `kubectl apply
--dry-run=server`) against the live cluster before merging. Document which values are "day-one only".

## Commands worth remembering
- `helm template ./chart | kubectl apply --dry-run=server -f -` - let the API server validate before you deploy
- `kubectl get statefulset <n> -o jsonpath='{.spec.volumeClaimTemplates}'` - what the live object has
- `kubectl delete statefulset <n> --cascade=orphan` - recreate the controller but keep pods and PVCs
- `kubectl get pvc` - the actual volumes (their size is independent of the template)

## Common mistakes
- Deleting the StatefulSet and PVCs "to get past the error" - this is how data is lost.
- Rolling back and losing the legitimate changes that were in the same release.
- Assuming a bigger `storage` in values resizes existing volumes.

## Helm 3 vs Helm 4
The same Kubernetes rule applies. Helm 4's error is wrapped as "server-side apply failed for object ... StatefulSet"
while Helm 3 says "cannot patch ... with kind StatefulSet".
