# The Kept Secret — Walkthrough

1. Reproduce: `helm install storefront ./storefront -n helmissions` fails with
   `annotation validation error: key "meta.helm.sh/release-name" must equal "storefront": current value is "shop"`.
2. Inspect the leftover:
   ```bash
   kubectl get secret db-credentials -n helmissions -o jsonpath='{.metadata.annotations}'
   # "helm.sh/resource-policy":"keep","meta.helm.sh/release-name":"shop", ...
   helm list -n helmissions            # no shop release any more
   ```
3. Transfer the Secret to the new release (any one of these):
   - `helm install storefront ./storefront -n helmissions --take-ownership --wait`
   - `kubectl annotate secret db-credentials -n helmissions --overwrite meta.helm.sh/release-name=storefront`, then install
     (Helm 4 may also need `--force-conflicts`)
   - `kubectl delete secret db-credentials -n helmissions` and install (the chart recreates it from values)
4. Verify: `helm get manifest storefront -n helmissions | grep -B2 -A8 'kind: Secret'` and the annotation names `storefront`. Run `check`.
