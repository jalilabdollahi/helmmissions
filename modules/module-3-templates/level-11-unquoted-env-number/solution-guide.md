# Number In An Env Var - Walkthrough

1. Install fails with `.env[name="WHOAMI_PORT_NUMBER"].value: expected string, got ...Value:2525`.
2. `helm template relay ./smtp-relay | grep -A1 WHOAMI_PORT_NUMBER` shows `value: 2525` - unquoted. The first env
   var, `WHOAMI_NAME`, is rendered `value: "outbound-relay-1"` (it uses `quote`).
3. In `templates/deployment.yaml` use `value: {{ .Values.listenPort | quote }}`. Quoting in values.yaml does not help:
   the template still prints the characters 2525 with no quotes around them.
4. Verify the render, then `helm upgrade --install relay ./smtp-relay -n helmissions --wait`
   (the failed attempt left a failed release behind; `upgrade --install` replaces it).
5. `kubectl exec` is not needed: `kubectl get pods -n helmissions -o jsonpath='{.items[0].spec.containers[0].env}'`.
