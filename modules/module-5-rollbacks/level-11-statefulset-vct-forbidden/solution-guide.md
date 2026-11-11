# Forbidden: StatefulSet Spec - Walkthrough

1. Reproduce and read the error:
   ```bash
   helm upgrade tsdb ./timeseries-db -n helmissions
   # StatefulSet.apps "tsdb" is invalid: spec.volumeClaimTemplates: Invalid value: [...]: field is immutable
   helm history tsdb -n helmissions
   ```
2. Find the change that is forbidden:
   ```bash
   helm get manifest tsdb -n helmissions | grep -A4 'requests:'     # storage: 1Gi
   grep -n storage timeseries-db/values.yaml                        # storage: 2Gi
   ```
3. `volumeClaimTemplates` is immutable. Keep the legal change (retention) and revert the illegal one: in
   `timeseries-db/values.yaml` set
   ```yaml
   retention: 14d
   storage: 1Gi
   ```
4. Upgrade and verify the data survived:
   ```bash
   helm upgrade tsdb ./timeseries-db -n helmissions --wait
   kubectl exec statefulset/tsdb -n helmissions -- cat /data/marker
   kubectl get statefulset tsdb -n helmissions -o jsonpath='{.spec.volumeClaimTemplates[0].spec.resources}'
   ```
5. Run `check`.
