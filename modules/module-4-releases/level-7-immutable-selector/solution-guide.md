# Field Is Immutable — Walkthrough

1. `helm history catalog-search -n helmissions` — revision 2 failed with `spec.selector ... field is immutable`.
2. Compare the selectors:
   ```bash
   kubectl get deploy catalog-search -n helmissions -o jsonpath='{.spec.selector.matchLabels}'   # {"app":"catalog-search"}
   helm template catalog-search ./catalog-search | grep -A4 'selector:'                           # new app.kubernetes.io/* labels
   ```
3. In `catalog-search/templates/_helpers.tpl` keep `selectorLabels` as `app: catalog-search` and make the `labels` helper
   emit selector labels plus `app.kubernetes.io/name`, `instance` and `version`.
4. Upgrade: `helm upgrade catalog-search ./catalog-search -n helmissions --wait`.
5. Verify the new pods carry `app.kubernetes.io/name` and that `helm history` still starts at revision 1. Run `check`.
