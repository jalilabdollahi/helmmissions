# Ship A Clean Package - Walkthrough

1. Look at what is in the chart directory and what a package would contain:
   ```bash
   ls -la reports
   helm package ./reports -d /tmp/probe && tar tzf /tmp/probe/reports-1.1.0.tgz
   # reports/secrets.local.env, reports/Chart.yaml.bak, reports/values.yaml.bak, reports/tmp/export-2026-10.csv ...
   ```
2. Tell Helm what to leave out. `.helmignore` lives in the chart root and uses .gitignore-like patterns:
   ```
   secrets.local.env
   *.bak
   tmp/
   ```
3. Package into `dist/` and verify the contents:
   ```bash
   helm package ./reports -d dist
   tar tzf dist/reports-1.1.0.tgz
   ```
4. Install from the package:
   ```bash
   helm install reports dist/reports-1.1.0.tgz -n helmissions --wait
   helm list -n helmissions      # reports-1.1.0
   ```
5. Run `check` in the game.
