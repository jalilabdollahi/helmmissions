# Another Operation In Progress — Walkthrough

1. Confirm the lock:
   ```bash
   helm upgrade warehouse-stock ./warehouse-stock -n helmissions
   # Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
   helm history warehouse-stock -n helmissions
   # 1 deployed         Install complete
   # 2 pending-upgrade  Preparing upgrade
   ```
2. Check nothing is really running (no helm process, CI job dead) — then unlock by creating a finished revision:
   ```bash
   helm rollback warehouse-stock 1 -n helmissions --wait
   helm history warehouse-stock -n helmissions      # 3 deployed  Rollback to 1
   ```
3. Redo the interrupted deploy:
   ```bash
   helm upgrade warehouse-stock ./warehouse-stock -n helmissions --wait
   ```
4. (Alternative to 2: `kubectl delete secret sh.helm.release.v1.warehouse-stock.v2 -n helmissions`.)
5. Verify status `deployed`, 2 replicas, then run `check`.
