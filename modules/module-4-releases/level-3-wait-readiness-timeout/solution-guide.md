# Timed Out Waiting — Walkthrough

1. Look at the release and its pods:
   ```bash
   helm history docs-portal -n helmissions     # rev 2 failed: "not ready ... context deadline exceeded"
   kubectl get pods -n helmissions             # one pod 0/1 Running
   ```
2. The container runs, so the image is fine. Ask Kubernetes why it is not Ready:
   ```bash
   kubectl describe pod -n helmissions -l app.kubernetes.io/name=docs-portal | grep -A3 -i readiness
   # Warning  Unhealthy  Readiness probe failed: HTTP probe failed with statuscode: 404
   ```
3. nginx serves the static site from `/` — it has no `/healthz`. Edit `docs-portal/values.yaml`:
   `readiness.path: /`.
4. Upgrade again, waiting for readiness:
   ```bash
   helm upgrade docs-portal ./docs-portal -n helmissions --wait --timeout 90s
   ```
5. Verify revision 3 is `deployed`, 2/2 pods are Ready and the probe is still in the Deployment. Run `check`.
