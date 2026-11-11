#!/bin/bash
# Valid alternative: make the test URL come from the template helpers/values instead of hard-coding it.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's#http://{{ .Release.Name }}:{{ .Values.service.port }}/health#http://{{ .Release.Name }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.service.port }}/#' "$SANDBOX/rating-service/templates/tests/test-connection.yaml"
rm -f "$SANDBOX/rating-service/templates/tests/test-connection.yaml.bak"
helm upgrade rating-service ./rating-service -n "$NS" --wait --timeout 90s
helm test rating-service -n "$NS" --timeout 60s
