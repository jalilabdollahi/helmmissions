# Migrations Before The Database — Walkthrough

1. See which hook failed and why:
   ```bash
   helm status orders -n helmissions
   kubectl get jobs -n helmissions                       # only orders-db-migrate exists, and it Failed
   kubectl logs job/orders-db-migrate -n helmissions     # schema 'orders' does not exist
   ```
   `orders-db-init` never ran: the migration Job was executed first and aborted the install.
2. List the hooks with their weights:
   ```bash
   helm get hooks orders -n helmissions | grep -E 'name:|hook-weight'
   ```
   The RBAC objects have weight -20, `db-init` has 10 and `db-migrate` has 0. Helm sorts ascending, so migrate runs before init.
3. Fix the chart: give `db-init-job.yaml` a weight lower than the migration (e.g. `"-5"`), or raise the weight of `db-migrate-job.yaml` above 10.
4. Deploy again:
   ```bash
   helm upgrade orders ./order-service -n helmissions --wait
   kubectl get configmap orders-schema-state -n helmissions -o yaml     # initialized-at, then migrated-at
   ```
5. Run `check`.
