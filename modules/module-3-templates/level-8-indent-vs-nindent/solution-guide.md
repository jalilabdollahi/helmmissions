# Misaligned Labels - Walkthrough

1. `helm template reconcile ./ledger-recon` fails: `yaml: line 5: mapping values are not allowed in this context`.
2. The YAML error is in the *rendered* text. Print it with `--debug` to see the first lines of the CronJob; or just
   compare `templates/cronjob.yaml` and `templates/configmap.yaml`.
3. The CronJob has `labels: {{ include "ledger-recon.labels" . | indent 4 }}`. `indent 4` prefixes every line with
   four spaces, including the first one, so the output is `labels:     app.kubernetes.io/name: ledger-recon` followed
   by indented lines - `labels:` can't have a scalar *and* a block.
4. Switch to `nindent`, which prepends a newline, and put the call on its own line:
   ```
   labels:
     {{- include "ledger-recon.labels" . | nindent 4 }}
   ```
   (the `{{-` swallows the stray newline and indentation before the action).
5. `helm install reconcile ./ledger-recon -n helmissions --wait`, then
   `kubectl get cronjob reconcile -n helmissions --show-labels`.
