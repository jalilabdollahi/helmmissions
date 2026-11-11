# Immutable ConfigMap - Walkthrough

1. Read the error and the history:
   ```bash
   helm upgrade flags ./feature-flags -n helmissions
   # ConfigMap "flags-flags" is invalid: data: Forbidden: field is immutable when `immutable` is set
   helm history flags -n helmissions
   ```
2. The ConfigMap is `immutable: true`, and the chart always names it `<release>-flags`. New data means
   "update that object", which Kubernetes forbids.
3. Make the name depend on the content. Add `templates/_helpers.tpl`:
   ```
   {{- define "feature-flags.configName" -}}
   {{ .Release.Name }}-flags-{{ .Values.flags | toJson | sha256sum | trunc 8 }}
   {{- end -}}
   ```
   Use `{{ include "feature-flags.configName" . }}` as the ConfigMap `metadata.name` and as the Deployment's
   volume `configMap.name`.
4. Upgrade:
   ```bash
   helm upgrade flags ./feature-flags -n helmissions --wait
   kubectl get configmap -n helmissions            # flags-flags-<hash>; the old map is removed by Helm
   curl via the Service: /flags.json -> {"checkoutV2":true,...}
   ```
5. Run `check` (it also installs and upgrades the chart in a throwaway namespace).
