#!/bin/bash
# Alternative: keep the call sites simple (include ... .) and make the helpers derive the component themselves.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cat > "$SANDBOX/mailer/templates/_helpers.tpl" <<'EOF'
{{- define "mailer.component" -}}
{{- base .Template.Name | trimSuffix ".yaml" -}}
{{- end -}}

{{- define "mailer.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "mailer.component" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mailer.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ include "mailer.component" . }}
{{- end -}}
EOF
sed -i.bak -E 's/\(dict "ctx" \. "component" "(api|worker)"\)/./' "$SANDBOX/mailer/templates/api.yaml" "$SANDBOX/mailer/templates/worker.yaml"
rm -f "$SANDBOX"/mailer/templates/*.bak
helm install mailer ./mailer -n "$NS" --wait --timeout 120s
