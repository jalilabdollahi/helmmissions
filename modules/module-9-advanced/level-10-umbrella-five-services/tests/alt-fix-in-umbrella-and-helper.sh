#!/bin/bash
# Valid alternative: supply pricing's limits from the umbrella values and make cart's helper read the global with `default`.
set -euo pipefail
source "$HM_LIB"

python3 - <<'PY'
p = "marketplace/values.yaml"
s = open(p).read()
s = s.replace("pricing:\n  currency: EUR", "pricing:\n  currency: EUR\n  resources:\n    limits:\n      cpu: 50m\n      memory: 64Mi")
open(p, "w").write(s)
PY
cat > marketplace/charts/cart/templates/_helpers.tpl <<'T'
{{- define "cart.image" -}}
{{- $registry := (.Values.global).imageRegistry | default .Values.imageRegistry -}}
{{- if $registry }}{{ $registry }}/{{ end }}{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- define "cart.selector" -}}
app.kubernetes.io/name: cart
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
T
helm install marketplace ./marketplace -n "$NS" --wait --timeout 180s
