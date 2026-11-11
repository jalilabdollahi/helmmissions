# Every Deploy Scales To 2

## What broke
The chart rendered `replicas: 2` on every upgrade while a HorizontalPodAutoscaler managed the same field.
The HPA scaled the Deployment up to 5; the next `helm upgrade` declared "replicas: 2" again and Kubernetes
obeyed. The autoscaler had to climb back up after every deploy, so each release caused a capacity dip at the
worst moment: under load.

## Why Helm behaves this way
Helm re-applies the full manifest on every upgrade; a field that is present in the chart is a field Helm owns.
The scale subresource that the HPA writes to is the same `spec.replicas` field, so the two controllers
fight. Helm 3 (and Helm 4 for releases applied client-side) simply patches the value back; Helm 4's
server-side apply for new releases notices that another field manager changed it and raises a conflict error
instead of silently overwriting it. The cure is the same either way: when an HPA is enabled, the chart must not
set `replicas` at all.

## The fix
Wrap `replicas` in `{{- if not .Values.autoscaling.enabled }}`. The first deploy after the change drops the
field from the manifest, so Kubernetes defaults the Deployment to 1 for a moment and the HPA corrects it; every
later deploy leaves the value alone. Roll the change out in a quiet period or temporarily raise `minReplicas`.

## In real life
`helm create` generates exactly this conditional - charts that were copy-pasted from older templates
often miss it. The same ownership rule applies to anything an operator mutates: replicas under KEDA, resource
requests under VPA, annotations injected by service meshes.

## Commands worth remembering
- `kubectl get hpa` and `kubectl describe hpa` - what the autoscaler thinks and does
- `helm template ./chart | grep -n replicas` - does the chart set the field?
- `kubectl get deploy <name> -o jsonpath='{.metadata.managedFields[*].manager}'` - who writes to the object

## Common mistakes
- Raising `replicaCount` to hide the dip - the autoscaler is still overruled on every deploy.
- Deleting the HPA instead of fixing the chart.
- Forgetting that the first deploy after the fix resets the count once.

## Helm 3 vs Helm 4
New Helm 4 releases use server-side apply and report a field-manager conflict on `.spec.replicas` when the HPA
has changed it, rather than resetting it. Releases created client-side (Helm 3 era, or `--server-side=false`)
keep the old silent reset - which is what this level reproduces.
