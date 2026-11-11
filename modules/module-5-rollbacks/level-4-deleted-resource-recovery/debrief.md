# Somebody Deleted The Service

## What broke
A `kubectl delete` removed the Service. Helm keeps no running controller: it only talks to the cluster when
you run a command, so the release still said `deployed` and `helm get manifest` still listed the Service,
while the cluster no longer had it. Pods kept running, but nothing could reach them by name.

## Why Helm behaves this way
A release is a record of what Helm last applied. When you run `helm upgrade` or `helm rollback`, Helm
applies every object of the new manifest; objects that the release owns but that no longer exist are
created again (a plain "no change" upgrade is enough). The recreated object gets Helm's ownership
metadata - the `app.kubernetes.io/managed-by: Helm` label and the `meta.helm.sh/release-name` and
`meta.helm.sh/release-namespace` annotations - and from then on `helm uninstall` removes it.

## The fix
Run the release again: `helm upgrade sms-gateway ./sms-gateway -n helmissions --wait`. A rollback to a
revision that contained the Service also works. Do not recreate the Service with `kubectl expose` or by
applying rendered YAML: it would exist, but Helm would not own it, and the next upgrade would fail with an
"invalid ownership metadata" error.

## In real life
Cleanup scripts that delete by label, namespace migrations and well-meaning `kubectl delete svc` calls
are the usual culprits. Where this matters, add `helm diff` or a drift check to the pipeline, restrict
delete permissions on production namespaces, or use a GitOps controller that reconciles continuously.

## Commands worth remembering
- `helm get manifest <rel>` - what the release believes exists
- `kubectl get <kind> <name> -o yaml | grep -i helm` - ownership annotations
- `helm upgrade <rel> ./chart --reuse-values` - re-apply without changing configuration
- `helm template ./chart -s templates/service.yaml` - render a single template

## Common mistakes
- Re-creating the object with `kubectl expose/apply` and leaving it outside the release.
- Uninstalling and reinstalling the whole release - needless downtime when one upgrade is enough.
- Assuming `helm status: deployed` means everything in the manifest still exists.

## Helm 3 vs Helm 4
Both re-create missing objects on upgrade or rollback. Helm 4 uses server-side apply for new releases, so
the recreated object carries `helm` as a field manager as well as the ownership annotations.
