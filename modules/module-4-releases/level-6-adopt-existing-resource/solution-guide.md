# Invalid Ownership Metadata — Walkthrough

1. Reproduce and read the error:
   ```bash
   helm install support-desk ./support-desk -n helmissions
   # ... ConfigMap "desk-settings" ... exists and cannot be imported into the current release: invalid ownership metadata
   kubectl get cm desk-settings -n helmissions -o yaml     # no Helm annotations/labels, data MAX_OPEN_TICKETS: "50"
   ```
2. Pick a strategy. The hand-made data is not wanted, so any of these work:
   - delete it: `kubectl delete cm desk-settings -n helmissions`, then `helm install ...`
   - adopt it with Helm: `helm install support-desk ./support-desk -n helmissions --take-ownership --force-conflicts`
     (Helm 4: without `--force-conflicts` the install fails with a server-side-apply conflict with `kubectl-create`;
     Helm 3.17+: `--take-ownership` is enough)
   - annotate and label it yourself (`meta.helm.sh/release-name`, `meta.helm.sh/release-namespace`,
     `app.kubernetes.io/managed-by=Helm`) and on Helm 4 install with `--server-side=false`
3. Verify:
   ```bash
   helm get manifest support-desk -n helmissions | grep -A6 'kind: ConfigMap'
   kubectl get cm desk-settings -n helmissions -o jsonpath='{.metadata.annotations}{"\n"}{.data}'
   ```
   `MAX_OPEN_TICKETS` must be `200`. Run `check`.
