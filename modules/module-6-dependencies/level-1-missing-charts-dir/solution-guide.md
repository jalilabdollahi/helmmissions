# Storefront Without Its Cache — Walkthrough

1. Reproduce the failure:
   ```bash
   cd sandbox/current
   helm install storefront ./storefront -n helmissions
   # Error: INSTALLATION FAILED: ... found in Chart.yaml, but missing in charts/ directory: session-cache
   ```
2. Ask Helm which dependencies it knows about:
   ```bash
   helm dependency list ./storefront
   # NAME            VERSION  REPOSITORY                  STATUS
   # session-cache   0.3.0    file://../session-cache     missing
   ls storefront/        # no charts/ directory
   ```
3. Fetch the dependency into `charts/`:
   ```bash
   helm dependency update ./storefront
   # Saving 1 charts
   ls storefront/charts   # session-cache-0.3.0.tgz
   cat storefront/Chart.lock
   helm dependency list ./storefront   # STATUS ok
   ```
   (`helm dependency build` works too: with no `Chart.lock` yet it resolves exactly like `update`.)
4. Install and verify:
   ```bash
   helm install storefront ./storefront -n helmissions --wait
   kubectl get deploy -n helmissions     # storefront and storefront-session-cache
   helm get manifest storefront -n helmissions | grep 'name: storefront-session-cache'
   ```
5. Run `check` in the game.
