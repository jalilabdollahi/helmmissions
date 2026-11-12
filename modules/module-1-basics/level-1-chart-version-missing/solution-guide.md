# The Nameless Chart — Walkthrough

1. Reproduce the failure from the workspace:
   ```bash
   cd sandbox/current
   helm install webapp ./webapp -n helmissions
   # Error: INSTALLATION FAILED: validation: chart.metadata.version is required
   ```
2. Ask Helm what is wrong with the chart itself:
   ```bash
   helm lint ./webapp
   # [ERROR] Chart.yaml: version is required
   ```
3. Open `webapp/Chart.yaml`. `appVersion: "1.27"` is the version of nginx, the application inside the
   chart. The chart's own `version` is missing. Add it:
   ```yaml
   version: 0.1.0
   ```
4. Lint again — `1 chart(s) linted, 0 chart(s) failed`.
5. Install and verify:
   ```bash
   helm install webapp ./webapp -n helmissions
   helm list -n helmissions          # CHART column shows webapp-0.1.0, APP VERSION 1.27
   kubectl get pods -n helmissions
   ```
6. Run `check` in the game.
