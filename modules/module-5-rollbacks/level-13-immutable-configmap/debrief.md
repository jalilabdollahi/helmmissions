# Immutable ConfigMap

## What broke
The ConfigMap carries `immutable: true`: once created, its `data` can never change and the kubelet stops
watching it. Chart 1.1.0 changed the flag defaults but kept the ConfigMap's name, so Helm tried to update the
existing object and the API server refused: `field is immutable when immutable is set`. The release stayed on
the old flags with revision 2 marked `failed`.

## Why Helm behaves this way
Helm updates objects in place by name. Immutability is a Kubernetes safeguard (protection against accidental
edits, and a big performance win on clusters with thousands of mounted ConfigMaps), and the only way to
"change" an immutable ConfigMap is to create a new one under a new name and repoint the workload. That is
exactly what a content hash in the name does: new data produces a new name, so Helm creates the new ConfigMap,
the Deployment's pod template changes (it references the new name) so pods roll automatically, and Helm
deletes the old ConfigMap because it is no longer in the manifest.

## The fix
Name the ConfigMap `<release>-flags-<hash of data>` using a shared helper, and mount that name from the
Deployment. As a bonus there is no need for a `checksum/config` annotation: the name itself drives the rollout.

## In real life
This is the pattern Kustomize's `configMapGenerator` uses. The catch is rollback: because old ConfigMaps are
deleted on upgrade, a rollback re-creates the previous map (it is part of that revision's manifest), which is
fine - but make sure hooks or other workloads do not hold a reference to a vanished name.

## Commands worth remembering
- `helm template ./chart --set flags.x=y | grep 'name: .*flags'` - see the name change with the data
- `kubectl get configmap -o custom-columns=NAME:.metadata.name,IMMUTABLE:.immutable`
- `sha256sum | trunc 8` in a helper - cheap content hash for names
- `helm upgrade --install` in CI against a throwaway namespace to prove a chart is upgradeable

## Common mistakes
- Removing `immutable: true` to make the error go away - that is itself a change to an immutable object, and
  it throws the protection away.
- Hashing only part of the data, so some changes still reuse the old name.
- Hashing the name in the ConfigMap but forgetting the Deployment's volume reference.

## Helm 3 vs Helm 4
Same Kubernetes rule. Helm 4 reports it as "server-side apply failed for object ... ConfigMap"; Helm 3 as
"cannot patch ... with kind ConfigMap".
