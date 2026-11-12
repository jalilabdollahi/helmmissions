# Chart.yml Is Not Chart.yaml - Walkthrough

1. Reproduce:
   ```bash
   helm install status-page ./status-page -n helmissions
   # Error: INSTALLATION FAILED: unable to detect chart at .../Chart.yaml: ... no such file or directory
   helm lint ./status-page
   ```
2. List the folder: `ls status-page` shows `Chart.yml`. Helm looks for `Chart.yaml` exactly.
3. Rename it:
   ```bash
   mv status-page/Chart.yml status-page/Chart.yaml
   helm lint ./status-page
   ```
4. Install and verify:
   ```bash
   helm install status-page ./status-page -n helmissions --wait
   helm list -n helmissions
   ```
5. Run `check` in the game.
