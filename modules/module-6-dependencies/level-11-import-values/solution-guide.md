# Parent Needs Child's Value — Walkthrough

1. Reproduce and read the whole output:
   ```bash
   cd sandbox/current
   helm template r ./invoicing
   # level=WARN msg="ImportValues missing table from chart" chart=pg-lite error="\"port\" is not a table"
   # Error: ... db.port is empty: it should be imported from the pg-lite subchart
   ```
2. Look at the import and at the subchart's values:
   ```bash
   grep -n -A3 import-values invoicing/Chart.yaml     # child: service.port  parent: db.port
   cat pg-lite/values.yaml                            # service: { port: 5432 }
   ```
   The import can only copy tables, and `service.port` is a scalar.
3. Import the `service` table into the parent's `db` key. In `invoicing/Chart.yaml`:
   ```yaml
       import-values:
         - child: service
           parent: db
   ```
4. Refresh the packaged dependency and install:
   ```bash
   helm dependency update ./invoicing
   helm template r ./invoicing | grep -A1 DB_PORT      # "5432"
   helm install invoicing ./invoicing -n helmissions --wait
   ```
5. Run `check`.
