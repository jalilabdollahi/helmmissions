# "No Tests Found" — Walkthrough

1. Compare the chart with the release:
   ```bash
   helm template search ./inventory-search | grep -c 'search-test'      # 0: the test pod is not even rendered as part of the manifest
   helm get hooks search -n helmissions                                  # empty
   helm status search -n helmissions                                     # TEST SUITE: None
   helm install --dry-run=client x ./inventory-search 2>&1 | grep -i unknown   # skipping unknown hooks hookTypes=tests
   ```
2. In `inventory-search/templates/tests/search-test.yaml` the annotation is `"helm.sh/hook": tests`. Helm silently skips unknown
   hook names. Change it to `"helm.sh/hook": test` (the legacy `test-success` also works).
3. The hook has to be stored in the release: upgrade, then run the test.
   ```bash
   helm upgrade search ./inventory-search -n helmissions --wait
   helm get hooks search -n helmissions         # now contains the test Pod
   helm test search -n helmissions --logs
   ```
4. Run `check`.
