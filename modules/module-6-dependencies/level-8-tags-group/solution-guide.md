# Toggle A Group — Walkthrough

1. See which monitoring component survived:
   ```bash
   cd sandbox/current
   kubectl get deploy -n helmissions       # tradedesk-api and tradedesk-log-shipper
   ```
2. Read the tags of each dependency:
   ```bash
   grep -n -A1 "tags:" tradedesk/Chart.yaml
   # metrics-agent: monitoring   log-shipper: monitorng   trace-collector: monitoring
   ```
   `values.yaml` switches `tags.monitoring`; nothing switches `monitorng`, so log-shipper stays enabled.
3. Fix the typo in `tradedesk/Chart.yaml` (`monitorng` → `monitoring`).
4. Refresh the lock (the declaration changed), prove the group toggles together, upgrade:
   ```bash
   helm dependency update ./tradedesk
   helm template t ./tradedesk | grep -c -E 'log-shipper|metrics-agent|trace-collector'            # 0
   helm template t ./tradedesk --set tags.monitoring=true | grep 'kind: Deployment' -A2 | grep name  # all three
   helm upgrade tradedesk ./tradedesk -n helmissions --wait
   ```
5. Run `check`.
