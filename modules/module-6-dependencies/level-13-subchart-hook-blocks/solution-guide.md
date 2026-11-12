# A Subchart's Hook Blocks Everything — Walkthrough

1. Read the Job's output:
   ```bash
   cd sandbox/current
   helm status checkout -n helmissions                  # STATUS: failed
   kubectl logs job/checkout-schema-migrator-migrate -n helmissions
   # schema-migrator: target database host=''
   # DB_HOST is empty - refusing to run migrations
   ```
2. Look at where that host comes from:
   ```bash
   helm template checkout ./checkout | grep -B3 -A3 DB_HOST
   cat schema-migrator/values.yaml checkout/values.yaml
   ```
   The API gets `database.host` from the parent; the subchart reads its *own* `database.host` (empty by default).
3. Scope the value to the subchart in `checkout/values.yaml`:
   ```yaml
   schema-migrator:
     database:
       host: orders-db.helmissions.svc.cluster.local
   ```
4. Re-run the release (a failed first release can simply be upgraded; `uninstall` + `install` also works):
   ```bash
   helm upgrade checkout ./checkout -n helmissions --wait
   kubectl logs job/checkout-schema-migrator-migrate -n helmissions   # migrations applied
   kubectl get deploy -n helmissions
   ```
5. Run `check`.
