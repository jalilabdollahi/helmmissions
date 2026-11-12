# Password In Git — Walkthrough

1. Look at what leaks:
   ```bash
   helm get values ledger-api -n helmissions
   kubectl get deploy ledger-api -n helmissions -o jsonpath='{.spec.template.spec.containers[0].env}'
   ```
   The password is in the values, in the Deployment spec and in every stored release revision.
2. Read `ledger-api/templates/deployment.yaml`. With `db.existingSecret` set, `DB_PASSWORD` is built with
   `valueFrom.secretKeyRef`; otherwise the literal `db.password` is inlined.
3. Create the Secret in the cluster, with a **new** password (the old one is compromised and must be
   rotated at the database too):
   ```bash
   kubectl create secret generic ledger-db-credentials -n helmissions \
     --from-literal=password="$(openssl rand -base64 18)"
   ```
4. Edit `ledger-api/values.yaml`: `password: ""` and `existingSecret: ledger-db-credentials`.
5. Upgrade and verify:
   ```bash
   helm upgrade ledger-api ./ledger-api -n helmissions -f ledger-api/values.yaml --wait
   helm get values ledger-api -n helmissions          # no password
   kubectl get pod -n helmissions                       # Ready
   ```
6. Run `check`.
