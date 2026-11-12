# Too Impatient — Walkthrough

1. Look at the failed hook and at the pods:
   ```bash
   helm status payments-gateway -n helmissions
   kubectl logs job/payments-gateway-smoke -n helmissions     # curl: (7) Failed to connect ...
   kubectl get pods -n helmissions                            # the gateway pod is Running but not Ready for ~10s
   ```
2. The gateway has `initialDelaySeconds: 10` on its readiness probe, and a Service has no endpoints before the pod is
   Ready. The post-install hook runs right after the resources are created, so the first (and only: `backoffLimit: 0`)
   attempt fails.
3. Fix it, either way:
   - make the hook patient: replace the single `curl` in `templates/smoke-test-job.yaml` with a retry loop
     (for example 30 attempts, 2 seconds apart), or raise `backoffLimit`; or
   - make the pipeline wait for readiness before post-install hooks run: add `--wait` to the `helm upgrade --install`
     line in `ci/deploy.sh`.
4. Deploy again (the failed release is upgraded in place):
   ```bash
   bash ci/deploy.sh
   kubectl logs job/payments-gateway-smoke -n helmissions
   ```
5. Run `check`; it also deploys the chart into a brand-new namespace using `ci/deploy.sh`.
