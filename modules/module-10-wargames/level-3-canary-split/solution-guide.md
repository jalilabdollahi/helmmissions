# Solution guide - The 50% Canary

1. `helm list -n helmissions --deployed --failed`: `catalog-canary` is `failed`. `kubectl get pods -n helmissions --show-labels`
   shows 1 stable pod and 1 canary pod that is `0/1`; the canary pod has `app.kubernetes.io/name=catalog-canary`.
2. `kubectl get endpointslices -l kubernetes.io/service-name=catalog` - only the stable pod is an endpoint (the Service selects
   `app.kubernetes.io/name=catalog`). So right now canary traffic is 0%; once the canary is fixed it would be 1 of 2 = 50%.
3. `kubectl describe pod` of the canary: `Readiness probe failed: HTTP probe failed with statuscode: 404` - `/health` is not served,
   the container serves `/healthz`.
4. Fix `values-canary.yaml` (remove `appName: catalog-canary`, set `probe.path: /healthz`) and `values-stable.yaml` (`replicaCount: 9`).
5. `bash release.sh` - the failed canary release is upgraded to a new revision and becomes `deployed`; stable scales to 9.
6. Verify: 10 endpoints, 1 of them canary; `for i in $(seq 100); do curl -s http://catalog/; done | sort | uniq -c` from a probe pod.
