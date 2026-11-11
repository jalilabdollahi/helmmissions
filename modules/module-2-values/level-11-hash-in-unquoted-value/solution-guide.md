# The Hash That Ate My Password - Walkthrough

1. Inspect the failing init container and the Secret:
   ```bash
   kubectl logs deploy/ledger-api -n helmissions -c auth-check
   # database rejected the credentials for user ledger
   kubectl get secret ledger-api-db -n helmissions -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
   # Harbor Light            <- the part after '#' is gone
   ```
2. `helm get values ledger-api -n helmissions` shows `password: Harbor Light` as well: the YAML parser treated
   ` #2024` as a comment (a `#` preceded by a space starts a comment in plain scalars).
3. Quote the scalar in `ledger-api/values.yaml`:
   ```yaml
   password: "Harbor Light #2024"
   ```
4. `helm upgrade ledger-api ./ledger-api -n helmissions` (the checksum annotation restarts the pod).
5. Verify the Secret and the pod, then run `check`.
