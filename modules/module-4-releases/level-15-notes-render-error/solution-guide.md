# Broken NOTES.txt — Walkthrough

1. Reproduce without a cluster:
   ```bash
   helm template status-page ./status-page
   # Error: ... NOTES.txt:4:23: executing ... nil pointer evaluating interface {}.host
   ```
2. `values.yaml` has no `ingress` key, yet `NOTES.txt` uses `.Values.ingress.host`.
3. Add to `status-page/values.yaml`:
   ```yaml
   ingress:
     host: status.example.test
   ```
   (or guard the line in NOTES.txt with `{{- if .Values.ingress }}`).
4. Install and read the notes:
   ```bash
   helm install status-page ./status-page -n helmissions --wait
   helm get notes status-page -n helmissions
   ```
5. Run `check`.
