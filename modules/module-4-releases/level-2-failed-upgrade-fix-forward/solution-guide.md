# Fix Forward — Walkthrough

1. Diagnose:
   ```bash
   helm status ledger-sync -n helmissions        # STATUS: failed, REVISION: 2
   helm history ledger-sync -n helmissions       # rev 1 deployed, rev 2 failed + error text
   ```
   The error says the readinessProbe specifies more than one handler type.
2. Inspect the template:
   ```bash
   helm template ledger-sync ./ledger-sync | grep -n -A8 readinessProbe
   ```
   The probe has both `httpGet` and `tcpSocket`.
3. Delete the `tcpSocket` block from `ledger-sync/templates/deployment.yaml` (keep `httpGet`).
4. Upgrade (do NOT roll back — that would remove `RECONCILE_MODE=incremental` and `BATCH_SIZE`):
   ```bash
   helm upgrade ledger-sync ./ledger-sync -n helmissions --wait
   ```
5. Verify: `helm history ledger-sync -n helmissions` shows rev 3 deployed, and
   `kubectl get deploy ledger-sync -n helmissions -o jsonpath='{.spec.template.spec.containers[0].env}'`
   shows the new variables. Run `check`.
