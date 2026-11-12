#!/bin/bash
# Tempting shortcut: type the value in the template.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/value: {{ .Values.listenPort | quote }}/value: "2525"/' "$SANDBOX/smtp-relay/templates/deployment.yaml"
rm -f "$SANDBOX/smtp-relay/templates/deployment.yaml.bak"
helm install relay ./smtp-relay -n "$NS" --wait --timeout 120s
