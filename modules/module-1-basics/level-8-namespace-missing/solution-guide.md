# Nowhere To Land - Walkthrough

1. Reproduce and read the error:
   ```bash
   helm install metrics-proxy ./metrics-proxy -n helmissions-staging
   # Error: INSTALLATION FAILED: create: failed to create: namespaces "helmissions-staging" not found
   kubectl get ns            # no helmissions-staging
   ```
2. Helm stores its release record as a Secret in the release namespace, and the manifests are created
   there too - so the namespace must exist first.
3. Install and create the namespace in one go:
   ```bash
   helm install metrics-proxy ./metrics-proxy -n helmissions-staging --create-namespace --wait
   ```
   (Equivalent: `kubectl create namespace helmissions-staging`, then the plain install.)
4. Verify:
   ```bash
   helm list -n helmissions-staging
   kubectl get pods -n helmissions-staging
   ```
5. Run `check` in the game.
