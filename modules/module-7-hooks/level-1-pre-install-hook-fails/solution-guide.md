# Blocked By A Hook — Walkthrough

1. Read the failure. The install error names the hook Job, so inspect it:
   ```bash
   helm status ledger-api -n helmissions         # STATUS: failed
   kubectl get jobs,pods -n helmissions          # ledger-api-migrate ... Error
   kubectl logs job/ledger-api-migrate -n helmissions
   # [migrate] FATAL: LEDGER_DB_DSN is not set, refusing to guess a database
   ```
2. Compare with the template. `ledger-api/templates/migrate-job.yaml` passes the connection string as
   `DATABASE_URL`, but the script reads `LEDGER_DB_DSN`. Rename the env var in the template to `LEDGER_DB_DSN`.
3. Deploy again. The Job is also a `pre-upgrade` hook, so either command works:
   ```bash
   helm upgrade ledger-api ./ledger-api -n helmissions --wait
   # or: helm uninstall ledger-api -n helmissions && helm install ledger-api ./ledger-api -n helmissions --wait
   ```
4. Verify: `kubectl logs job/ledger-api-migrate -n helmissions` ends with "3 migrations applied", and
   `helm status ledger-api -n helmissions` says `deployed`. Run `check`.
