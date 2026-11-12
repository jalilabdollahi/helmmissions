# Immutable Job Template

## What broke
Chart 1.1.0 changed the seed Job's environment (`SEED_VERSION` 1 to 2) but kept the Job's name. The Job
from revision 1 still exists (finished), and the API server does not allow `spec.template` of an existing
Job to change. Helm's update of that object is rejected, so the whole upgrade fails and the new revision
is recorded as `failed`.

## Why Helm behaves this way
Helm updates an object by patching it towards the new manifest. Kubernetes marks several fields immutable
once an object exists: a Job's pod template and selector, a Deployment's selector, a Service's clusterIP,
a StatefulSet's volumeClaimTemplates. A patch that touches them is an error, not a restart. People reach for
`--force` (Helm 4: `--force-replace`), which switches Helm from patching to delete-and-recreate semantics.
In practice that does not rescue Jobs: Helm 4 refuses to combine it with server-side apply, and with
client-side apply the replacement is rejected because the live Job's generated selector is immutable. What
does work: remove the old Job so Helm can create the new one, or give each version of the Job its own name.

## The fix
Put the seed version in the Job name (`{{ .Release.Name }}-seed-v{{ .Values.seed.version }}`): an upgrade
then creates a new Job and removes the old one because it is no longer in the manifest. Deleting the finished
Job by hand and re-running the upgrade also works. `ttlSecondsAfterFinished` helps for future cleanups.

## In real life
Seed, migration and report Jobs shipped as ordinary release resources (not hooks) are a classic source of
"field is immutable" failures. Most teams either use hooks with `before-hook-creation`, give Jobs a unique
name per release/revision/hash, or let a TTL clean them up.

## Commands worth remembering
- `helm history <rel>` - the failed revision's description carries the API error
- `kubectl delete job <name>` - remove the finished Job so Helm can create the new one
- `helm template ./chart | kubectl diff -f -` - preview which objects changed
- `helm upgrade --force-replace` (Helm 3: `--force`) - replace instead of patch; not a cure for Jobs

## Common mistakes
- Retrying with `--force-replace` and expecting it to bypass immutability.
- Rolling back: the release is `deployed` again but the new dataset never ran.
- Deleting the Deployment/namespace "to be clean" instead of the one stuck object.

## Helm 3 vs Helm 4
The immutable error is the same, but Helm 4 wraps it in "server-side apply failed for object ...".
`--force` was renamed `--force-replace` and cannot be combined with `--server-side`; pass
`--server-side=false` if you really need replace semantics.
