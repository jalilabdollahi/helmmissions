# Bring Back Revision 2's Setting — Walkthrough

1. Walk the history and diff the user values of consecutive revisions:
   ```bash
   helm history product-search -n helmissions
   for r in 2 3 4 5; do echo "--- rev $r"; helm get values product-search -n helmissions --revision $r; done
   ```
   Revision 3 added `features.search: false`; 4 added `cache.ttlSeconds: 600`; 5 added `logLevel: warn`; 2 added `replicaCount: 2`.
2. `helm rollback product-search 2` would bring search back but also remove 4 and 5. Don't.
3. Create a new revision that flips only the bad value:
   ```bash
   helm upgrade product-search ./product-search -n helmissions --reuse-values --set features.search=true --wait
   ```
4. Verify: `helm get values product-search -n helmissions` and
   `kubectl get cm product-search-config -n helmissions -o jsonpath='{.data}'`. Run `check`.
