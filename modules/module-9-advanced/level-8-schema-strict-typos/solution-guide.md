# Catch Typos With A Schema — Walkthrough

1. See what the release actually kept:
   ```bash
   helm get values queue-worker -n helmissions
   # replicaCnt: 3     <- the chart reads replicaCount, so this is ignored
   # probes: {readiness: {periodSecond: 5}}   <- also ignored (it is periodSeconds)
   kubectl get deploy queue-worker -n helmissions    # 1/1
   ```
2. Add `queue-worker/values.schema.json` that mirrors `values.yaml`: integer `replicaCount` and `concurrency`,
   string-or-number `cpu`/`memory`, integer probe settings, free-form `extraEnv` / `podAnnotations`, and `"additionalProperties": false` on the top
   level and on `image`, `resources`, `resources.requests`, `resources.limits`, `probes` and `probes.readiness`.
3. Run the production file through it:
   ```bash
   helm template queue-worker ./queue-worker -f values-prod.yaml
   # Error: values don't meet the specifications of the schema(s) ... additional properties 'replicaCnt' not allowed
   ```
4. Fix `values-prod.yaml` (`replicaCount: 3`, `probes.readiness.periodSeconds: 5`), then deploy:
   ```bash
   helm lint ./queue-worker -f values-prod.yaml
   helm upgrade queue-worker ./queue-worker -n helmissions -f values-prod.yaml --wait
   ```
5. Verify 3 ready replicas; try `helm template ./queue-worker --set replicaCnt=3` and watch it fail.
