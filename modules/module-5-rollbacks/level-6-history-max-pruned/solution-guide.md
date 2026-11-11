# The Good Revision Is Gone - Walkthrough

1. Try the obvious thing and see why it fails:
   ```bash
   helm history geo-lookup -n helmissions        # starts at revision 2
   helm rollback geo-lookup 1 -n helmissions     # Error: ... revision "1" ... not found
   ```
2. Look at the revisions that are left:
   ```bash
   helm get values geo-lookup -n helmissions --revision 2   # provider: maps-v1 (retired)
   helm get values geo-lookup -n helmissions --revision 3
   helm get values geo-lookup -n helmissions                # provider: maps-v1-eu, ttl: 0, trace: true
   ```
   All three are broken, so a rollback to any of them is pointless.
3. Work out the good configuration: chart defaults say `provider: maps-v2`, `ttl: 300`, `trace: false`.
   `values-prod.yaml` overrides all three with the migration leftovers. Remove those overrides:
   ```yaml
   replicaCount: 1
   ```
4. Deploy as the pipeline does and verify:
   ```bash
   bash ci/deploy.sh
   helm history geo-lookup -n helmissions        # revisions 3, 4, 5
   ```
5. `GET /lookup` now returns `{"provider":"maps-v2","ttl":300,"trace":false}`. Run `check`.
