# DRY With A Library — Walkthrough

1. See the drift:
   ```bash
   kubectl get deploy -n helmissions --show-labels
   diff ledger-api/templates/_helpers.tpl ledger-worker/templates/_helpers.tpl
   ```
   The api has no `part-of`, the worker says `ledger-platform` and `managed-by: helm`.
2. Create the library chart `platformlib/`:
   ```yaml
   # platformlib/Chart.yaml
   apiVersion: v2
   name: platformlib
   type: library
   version: 0.1.0
   ```
   and `platformlib/templates/_labels.tpl` with `platformlib.selectorLabels` (name + instance) and
   `platformlib.labels` (selector labels + chart, version, part-of: ledger, managed-by).
3. In both app charts add
   ```yaml
   dependencies:
     - name: platformlib
       version: 0.1.0
       repository: file://../platformlib
   ```
   delete `templates/_helpers.tpl`, and change every `include "ledger-api.labels"` /
   `include "ledger-worker.labels"` (and the selectorLabels includes) to the library names.
4. Vendor the library and roll out:
   ```bash
   helm dependency update ./ledger-api
   helm dependency update ./ledger-worker
   helm template ledger-api ./ledger-api | grep -A8 'labels:'
   helm upgrade ledger-api ./ledger-api -n helmissions --wait
   helm upgrade ledger-worker ./ledger-worker -n helmissions --wait
   ```
5. Verify: `kubectl get deploy -n helmissions --show-labels` shows the same six label keys on both.
