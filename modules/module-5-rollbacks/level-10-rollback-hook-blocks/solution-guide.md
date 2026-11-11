# Pre-rollback Hook Says No - Walkthrough

1. Reproduce the failing rollback and look at the history:
   ```bash
   helm rollback settlement-batch 1 -n helmissions
   # Error: resource Job/helmissions/settlement-batch-drain not ready. status: Failed
   helm history settlement-batch -n helmissions     # stale pending-rollback revisions appear
   ```
2. Find the cause:
   ```bash
   helm get hooks settlement-batch -n helmissions   # pre-rollback Job
   kubectl logs job/settlement-batch-drain -n helmissions
   # draining settlement queue via queue-admin / wget: bad address 'queue-admin.helmissions.svc' / queue-admin unreachable
   ```
3. The queue-admin service no longer exists, so the hook can never succeed. Recover without running hooks:
   ```bash
   helm rollback settlement-batch 1 -n helmissions --no-hooks --wait
   ```
   (A plain `helm upgrade` would not help: the failed rollback left the release in `pending-rollback`, and Helm
   answers "another operation (install/upgrade/rollback) is in progress".)
4. Verify:
   ```bash
   helm history settlement-batch -n helmissions     # newest: deployed, "Rollback to 1"
   kubectl get pods -n helmissions
   ```
5. Afterwards, fix the hook in the chart so the next rollback does not hit the same wall. Run `check`.
