# Disabled But Still Deployed — Walkthrough

1. See the symptom:
   ```bash
   cd sandbox/current
   kubectl get deploy -n helmissions          # helpdesk-web and helpdesk-ticket-search
   helm template helpdesk ./helpdesk | grep -c ticket-search
   ```
2. Read the declaration and the value:
   ```bash
   grep -n -B1 -A3 condition helpdesk/Chart.yaml   # condition: search.enable
   cat helpdesk/values.yaml                        # search: enabled: false
   ```
   The condition path `search.enable` does not exist in the values, so Helm treats the dependency as enabled.
3. Make the path match the key. Edit `helpdesk/Chart.yaml`:
   ```yaml
       condition: search.enabled
   ```
4. Prove it renders correctly both ways, then upgrade:
   ```bash
   helm template helpdesk ./helpdesk | grep -c ticket-search                      # 0
   helm template helpdesk ./helpdesk --set search.enabled=true | grep -c ticket-search   # > 0
   helm dependency update ./helpdesk      # refresh Chart.lock (declaration changed)
   helm upgrade helpdesk ./helpdesk -n helmissions --wait
   kubectl get deploy -n helmissions
   ```
5. Run `check`.
