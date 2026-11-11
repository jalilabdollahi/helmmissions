# Lost In with - Walkthrough

1. Reproduce: `helm template tiles ./tileserver` fails with
   `nil pointer evaluating interface {}.Name` at line 18 of `templates/deployment.yaml`.
2. Look at the lines above: the failing `{{ .Release.Name }}` is inside `{{- with .Values.podLabels }}`.
   `with` rebinds `.` to `.Values.podLabels` (a map with `team` and `cost-center`). `.Release` on that map is
   nil, and `.Name` of nil is the pointer error.
3. Use the root context `$` (set once at the start of the template and never rebound):
   `tileserver.example.com/release: {{ $.Release.Name }}`.
4. Check: `helm template tiles ./tileserver | grep -B2 -A4 'team:'`.
5. Install and verify:
   ```bash
   helm install tiles ./tileserver -n helmissions --wait
   kubectl get pods -n helmissions --show-labels
   ```
