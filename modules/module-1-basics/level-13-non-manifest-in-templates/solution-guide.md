# Not Every File Is A Manifest - Walkthrough

1. Reproduce and locate:
   ```bash
   helm install helpdesk ./helpdesk -n helmissions
   # Error: ... YAML parse error on helpdesk/templates/usage-notes.yaml: ... line 6: mapping values are not allowed
   helm lint ./helpdesk
   cat helpdesk/templates/usage-notes.yaml        # prose, not Kubernetes YAML
   ```
2. Everything in `templates/` is rendered and then parsed as YAML manifests. The only special-cased files
   are `_*.tpl` helpers (not rendered as manifests) and `NOTES.txt` (rendered, printed after install/upgrade).
3. Rename the file to `NOTES.txt` (or move it out of `templates/`, e.g. to `docs/`):
   ```bash
   mv helpdesk/templates/usage-notes.yaml helpdesk/templates/NOTES.txt
   helm lint ./helpdesk
   helm template helpdesk ./helpdesk | grep ^kind
   ```
4. Install: `helm install helpdesk ./helpdesk -n helmissions --wait` - the notes are printed at the end.
5. Run `check` in the game.
