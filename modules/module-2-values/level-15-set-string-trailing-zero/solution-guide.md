# 1.10 Became 1.1 - Walkthrough

1. Compare:
   ```bash
   grep appVersionLabel status-page/values.yaml     # 1.10
   helm get values status-page -n helmissions       # appVersionLabel: 1.1
   kubectl get pods -n helmissions --show-labels
   ```
2. Unquoted `1.10` is parsed by YAML as the float 1.1; the trailing zero is not part of a number's value.
3. Make it a string in `status-page/values.yaml`:
   ```yaml
   appVersionLabel: "1.10"
   ```
   (or keep the file and add `--set-string appVersionLabel=1.10` to the deploy command).
4. Redeploy: `./deploy.sh`.
5. Verify: `kubectl get pods -n helmissions -L app.version`, then run `check`.
