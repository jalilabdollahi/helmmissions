#!/bin/bash
# Alternative: scope the names by release name alone, and install team-b first.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
cat >collector/templates/_helpers.tpl <<'TPL'
{{- define "collector.scope" -}}
{{ .Release.Name }}
{{- end -}}
TPL
helm upgrade --install team-b ./collector -n helmissions-team-b -f values/team-b.yaml --wait --timeout 60s
helm upgrade --install team-a ./collector -n helmissions-team-a -f values/team-a.yaml --wait --timeout 60s
