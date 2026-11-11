# The CRD That Never Updated - Walkthrough

1. Reproduce and read the error:
   ```bash
   helm upgrade snapshots ./snapshot-scheduler -n helmissions
   # ... .spec.retentionDays: field not declared in schema
   helm history snapshots -n helmissions      # revision 2 failed
   ```
2. Compare schemas:
   ```bash
   kubectl get crd snapshotpolicies.helmissions.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties}' | jq
   cat snapshot-scheduler/crds/snapshotpolicy.yaml        # has retentionDays
   ```
   The cluster still holds the 1.0.0 schema: Helm never touches `crds/` after the first install.
3. Apply the new CRD manually:
   ```bash
   kubectl apply -f snapshot-scheduler/crds/
   ```
4. Run the upgrade again:
   ```bash
   helm upgrade snapshots ./snapshot-scheduler -n helmissions --wait
   kubectl get snapshotpolicy nightly -n helmissions -o yaml | grep retention
   ```
5. Run `check`.
