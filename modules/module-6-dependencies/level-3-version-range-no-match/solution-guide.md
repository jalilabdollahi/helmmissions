# No Matching Version — Walkthrough

1. Reproduce:
   ```bash
   cd sandbox/current
   helm dependency update ./searchdesk
   # Error: can't get a valid version for 1 subchart(s): "redis-lite" ... version "^2.0.0"
   ```
2. List what the repository serves:
   ```bash
   helm repo add hm-platform http://localhost:8879/m6-version-range-no-match
   helm search repo hm-platform/redis-lite --versions
   # 1.2.4, 1.2.3, 1.2.0
   ```
3. The caret range `^2.0.0` allows only 2.x. Change the constraint in `searchdesk/Chart.yaml`:
   ```yaml
   dependencies:
     - name: redis-lite
       version: "~1.2.0"
       repository: http://localhost:8879/m6-version-range-no-match
   ```
4. Resolve and install:
   ```bash
   helm dependency update ./searchdesk     # Chart.lock now pins 1.2.4
   helm install searchdesk ./searchdesk -n helmissions --wait
   kubectl get deploy -n helmissions -L helm.sh/chart
   ```
5. Run `check`.
