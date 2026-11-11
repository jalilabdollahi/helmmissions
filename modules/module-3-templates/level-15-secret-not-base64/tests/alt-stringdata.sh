#!/bin/bash
# Alternative: use stringData and let the API server encode it.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/^data:/stringData:/; s/{{ .Values.provider.apiKey | b64enc | quote }}/{{ .Values.provider.apiKey | quote }}/' "$SANDBOX/payments-gw/templates/secret.yaml"
rm -f "$SANDBOX/payments-gw/templates/secret.yaml.bak"
helm install gateway ./payments-gw -n "$NS" --wait --timeout 120s
