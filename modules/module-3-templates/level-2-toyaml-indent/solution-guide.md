# Mis-indented Resources - Walkthrough

1. Reproduce the failure:
   ```bash
   helm install geoip ./geoip -n helmissions
   # ... .containers[name="lookup"].limits: field not declared in schema
   ```
   The API server says `limits` is not a field *of the container* - so it is in the wrong place.
2. Look at what Helm renders:
   ```bash
   helm template geoip ./geoip | sed -n '/containers:/,$p'
   ```
   `resources:` is empty and `limits:`/`requests:` are at the same level as `resources:`.
3. In `templates/deployment.yaml` the line is `{{- toYaml .Values.resources | nindent 10 }}` but the
   `resources:` key is at 10 spaces, so its children need 12.
4. Change `nindent 10` to `nindent 12`.
5. Install. The failed attempt left a failed release record, so either remove it or let Helm replace it:
   ```bash
   helm upgrade --install geoip ./geoip -n helmissions --wait
   kubectl get deploy geoip-lookup -n helmissions -o jsonpath='{.spec.template.spec.containers[0].resources}'
   ```
