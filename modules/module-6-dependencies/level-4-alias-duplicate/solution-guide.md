# Same Chart Twice — Walkthrough

1. Reproduce:
   ```bash
   cd sandbox/current
   helm dependency update ./inventory
   # Error: validation: more than one dependency with name or alias "kvstore"
   ```
2. Give each instance an alias in `inventory/Chart.yaml`. The aliases must match the top-level keys already
   present in `values.yaml`, because the alias is the key Helm uses to scope values to that instance:
   ```yaml
   dependencies:
     - name: kvstore
       alias: primary
       version: 0.2.0
       repository: file://../kvstore
     - name: kvstore
       alias: replica
       version: 0.2.0
       repository: file://../kvstore
   ```
3. Package and install:
   ```bash
   helm dependency update ./inventory
   helm install inventory ./inventory -n helmissions --wait
   ```
4. Verify both instances got their own settings:
   ```bash
   kubectl get deploy -n helmissions
   helm get manifest inventory -n helmissions | grep -E 'name: inventory-|KV_MODE' -A1
   ```
5. Run `check`.
