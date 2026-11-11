# No Endpoints

## What broke
The Service's selector was typed by hand (`app: payments`) while the pods were labelled by the chart's helper
(`app.kubernetes.io/name` and `app.kubernetes.io/instance`). A Service routes only to pods whose labels contain *every*
key/value of its selector, so it matched nothing and its Endpoints/EndpointSlices were empty. The pods were healthy and
Helm reported success - the break was in the wiring between two objects.

## Why Helm behaves this way
Helm cannot know that a Service selector must match a Deployment's pod template; they are just two YAML documents. Charts
solve this by generating both from one helper: `selectorLabels` is the stable subset (name, instance) used in `selector`
fields, and a fuller `labels` helper adds version and managed-by for metadata. Selectors of a Deployment are immutable, so
the selector helper must contain only values that never change (not the chart version or appVersion) - another reason to
keep it separate and shared.

## The fix
Use `include "payments.selectorLabels"` in the Service. After `helm upgrade` the Service selector equals the Deployment's
selector, in every release name, so two releases of this chart in one namespace never select each other's pods.

## In real life
This is the top cause of "the pod is fine but the Service times out". Hand-written labels survive renames, chart
refactors and label standardisation projects (`app` -> `app.kubernetes.io/name`) in only one of the two templates. Quick
checks: `kubectl get endpoints <svc>`, `kubectl describe svc <svc>` and comparing `--show-labels` on pods.

## Commands worth remembering
- `kubectl get endpoints <svc> -n <ns>` / `kubectl get endpointslices -l kubernetes.io/service-name=<svc>`
- `kubectl get pods -n <ns> --show-labels` and `-l key=value` to test a selector
- `helm template ./chart | grep -A4 selector:`

## Common mistakes
- Adding the old label to the pods: it works for one release name, breaks the multi-release isolation, and changes the
  pod template (rolling restart).
- Patching the live Service with `kubectl`: gone at the next upgrade.
- Putting the chart version in the selector helper: the next `helm upgrade` then fails on the immutable Deployment selector.

## Helm 3 vs Helm 4
No difference in templating. The immutable-selector failure mentioned above is reported as `field is immutable` by both.
