# Kustomize Inflates Helm — Walkthrough

1. Build the folder:
   ```bash
   kubectl kustomize --enable-helm platform
   # error: no repo specified for pull, no chart found at ''
   ls platform/charts            # catalog-api lives here
   ```
2. `helmGlobals.chartHome` says `helm-charts`, but the vendored charts are in `charts`. Fix it:
   ```yaml
   helmGlobals:
     chartHome: charts
   ```
3. Build again — the next error names the values file:
   ```
   error: evalsymlink failure on '.../platform/values-prod.yaml' : ... no such file or directory
   ```
   Values files are resolved relative to the kustomization directory. Use `valuesFile: values/prod.yaml`.
4. Check the rendered output (2 replicas, `CACHE_TTL_SECONDS: "600"`, `env: prod` on objects and pod template), then apply:
   ```bash
   kubectl kustomize --enable-helm platform | kubectl apply -f -
   kubectl rollout status deployment/catalog-api -n helmissions
   ```
5. No Helm release exists (`helm list -n helmissions` is empty): kustomize only used Helm to render.
