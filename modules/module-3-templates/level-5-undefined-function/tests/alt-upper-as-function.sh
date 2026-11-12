#!/bin/bash
# Alternative: call upper in prefix notation.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/{{ .Values.environment | upper | quote }}/{{ upper .Values.environment | quote }}/' "$SANDBOX/dispatch/templates/deployment.yaml"
rm -f "$SANDBOX/dispatch/templates/deployment.yaml.bak"
helm install dispatch ./dispatch -n "$NS" --wait --timeout 120s
