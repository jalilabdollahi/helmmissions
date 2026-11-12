#!/bin/bash
# Valid alternative: a differently named library in a libs/ folder, different template names, charts bumped.
set -euo pipefail
source "$HM_LIB"

mkdir -p libs/ledgerkit/templates
cat > libs/ledgerkit/Chart.yaml <<'Y'
apiVersion: v2
name: ledgerkit
version: 1.0.0
type: library
Y
cat > libs/ledgerkit/templates/_std.tpl <<'T'
{{- define "ledgerkit.sel" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "ledgerkit.all" -}}
{{ include "ledgerkit.sel" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: ledger
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
T
for c in ledger-api ledger-worker; do
  rm "$c/templates/_helpers.tpl"
  sed -i.bak "s/include \"$c.labels\"/include \"ledgerkit.all\"/; s/include \"$c.selectorLabels\"/include \"ledgerkit.sel\"/" "$c"/templates/*.yaml
  rm "$c"/templates/*.bak
  printf 'dependencies:\n  - name: ledgerkit\n    version: 1.0.0\n    repository: file://../libs/ledgerkit\n' >> "$c/Chart.yaml"
  helm dependency update "./$c"
  helm upgrade "$c" "./$c" -n "$NS" --wait --timeout 120s
done
