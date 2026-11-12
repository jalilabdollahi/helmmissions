# Ship Via OCI — Walkthrough

1. Reproduce the failure:
   ```bash
   ./deploy.sh
   # Error: UPGRADE FAILED: failed to perform "FetchReference" ... charts/payments-gateway:0.3.0: not found
   ```
2. Ask the registry what exists:
   ```bash
   curl -s http://localhost:5001/v2/_catalog | jq
   ```
   Next to `.../charts/payments-gateway` (0.2.0) there is a second repository
   `.../charts/payments-gateway/payments-gateway` — the push went there.
3. `helm push FILE oci://HOST/PATH` stores the chart at `HOST/PATH/<chart name>:<chart version>`. `release.sh`
   already put the chart name into PATH, so it got doubled. Edit the push line:
   ```bash
   helm push dist/payments-gateway-*.tgz "oci://$REGISTRY/$BASE/charts" --plain-http
   ```
4. Publish and roll out:
   ```bash
   ./release.sh
   helm show chart oci://localhost:5001/<base>/charts/payments-gateway --version 0.3.0 --plain-http
   ./deploy.sh
   ```
5. Verify `helm list -n helmissions` shows `payments-gateway-0.3.0` at revision 2 and two ready pods.
