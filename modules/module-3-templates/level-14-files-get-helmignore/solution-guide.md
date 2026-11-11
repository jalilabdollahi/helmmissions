# The Vanishing Config File - Walkthrough

1. `kubectl get pods -n helmissions` shows `site-...` Running but 0/1; `kubectl describe pod` shows readiness probe
   failures on /healthz (connection refused: nginx has no server block).
2. `kubectl get configmap site-nginx -n helmissions -o yaml` - `default.conf` is empty.
3. `helm template site ./legacy-site -s templates/configmap.yaml` reproduces it locally: `.Files.Get "files/site.conf"`
   returns an empty string, without an error.
4. `ls -a legacy-site` shows a `.helmignore`. It contains `*.conf`, so Helm excludes `files/site.conf` while loading the chart.
5. Delete that line (or narrow it), re-run the template command: the server block appears.
6. `helm upgrade site ./legacy-site -n helmissions --wait`; check `kubectl get pods -n helmissions`.
