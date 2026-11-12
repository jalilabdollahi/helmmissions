# The Policy Gate — Walkthrough

1. Run the gate:
   ```bash
   bash ci/policy.sh
   ```
   It lists five violations: `worker` uses `nginx:latest` and lacks limits and a liveness probe;
   `log-shipper` lacks limits and both probes.
2. `values.yaml`: set `image.tag: 1.27-alpine` and add limits to both resource blocks:
   ```yaml
   resources:
     requests: {cpu: 10m, memory: 16Mi}
     limits:   {cpu: 100m, memory: 64Mi}
   ```
   (same for `shipper.resources`).
3. `templates/deployment.yaml`: add `livenessProbe` (httpGet `/` on `http`) to `worker`; give `log-shipper`
   a `readinessProbe` and a `livenessProbe` (e.g. `exec: test -f /tmp/alive`, created by the shell loop).
4. Re-run `bash ci/policy.sh` until it prints `policy gate passed`.
5. Deploy: `helm upgrade --install report-worker ./report-worker -n helmissions --wait`.
6. Run `check`.
