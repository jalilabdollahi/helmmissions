# No Endpoints - Walkthrough

1. `kubectl get pods -n helmissions --show-labels`: pods carry `app.kubernetes.io/name=payments` and
   `app.kubernetes.io/instance=payments` (plus version).
2. `kubectl get svc payments -n helmissions -o jsonpath='{.spec.selector}'` is `{"app":"payments"}` - no pod has that label,
   so `kubectl get endpoints payments -n helmissions` is empty (the Service is healthy, it just selects nothing).
3. In `templates/service.yaml` the selector is typed by hand; `templates/deployment.yaml` uses
   `include "payments.selectorLabels"`. Use the same helper in the Service.
4. `helm template payments ./payments | grep -B1 -A4 'selector:'` - both selectors are identical.
5. `helm upgrade payments ./payments -n helmissions --wait`; `kubectl get endpoints payments -n helmissions` lists two addresses.
