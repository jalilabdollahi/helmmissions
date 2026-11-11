# The Schema Says No - Walkthrough

1. Read the error. Two violations are listed with JSON-pointer style paths:
   `/replicas: minimum: got 0, want 1` and `/logLevel: value must be one of 'debug', 'info', 'warn', 'error'`.
2. Open `search-api/values.schema.json` to see the rules, and `search-api/values.yaml` to see the offending values
   (`replicas: 0`, `logLevel: WARN`).
3. Fix the VALUES, not the schema:
   ```yaml
   replicas: 2
   logLevel: warn
   ```
4. `helm lint ./search-api`, then `helm install search-api ./search-api -n helmissions`.
5. Verify `kubectl get pods -n helmissions`, then run `check`. (`--skip-schema-validation` would install with the
   bad values and is not a fix.)
