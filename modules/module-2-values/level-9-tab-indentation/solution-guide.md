# Invisible Tabs - Walkthrough

1. Reproduce and locate:
   ```bash
   helm install audit-log ./audit-log -n helmissions
   # ... found character that cannot start any token
   helm lint ./audit-log
   ```
2. Make the whitespace visible:
   ```bash
   grep -nP '\t' audit-log/values.yaml          # or: cat -A audit-log/values.yaml | head -20
   ```
   Lines 9-13 start with `^I` (tab).
3. Replace the tabs with spaces in `audit-log/values.yaml` (editor setting "convert tabs to spaces", or
   `sed -i.bak $'s/\t/  /g' audit-log/values.yaml`). Keep the nesting:
   ```yaml
   audit:
     retentionDays: 90
     sink:
       host: siem.corp.example
       port: 6514
       tls: true
   ```
4. `helm lint ./audit-log`, then `helm install audit-log ./audit-log -n helmissions`.
5. Run `check`.
