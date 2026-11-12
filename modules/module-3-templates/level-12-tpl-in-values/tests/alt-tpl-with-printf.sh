#!/bin/bash
# Alternative: keep the template string in values but render it with tpl and a different quoting style.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/value: {{ tpl .Values.database.host . | quote }}/value: {{ tpl (toString .Values.database.host) $ | quote }}/' "$SANDBOX/orders-api/templates/deployment.yaml"
rm -f "$SANDBOX/orders-api/templates/deployment.yaml.bak"
helm upgrade orders ./orders-api -n "$NS" --wait --timeout 120s
