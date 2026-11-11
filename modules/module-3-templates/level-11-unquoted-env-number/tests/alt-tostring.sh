#!/bin/bash
# Alternative: explicit string conversion plus quoting in the template.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/{{ .Values.listenPort | quote }}/"{{ .Values.listenPort }}"/' "$SANDBOX/smtp-relay/templates/deployment.yaml"
rm -f "$SANDBOX/smtp-relay/templates/deployment.yaml.bak"
helm install relay ./smtp-relay -n "$NS" --wait --timeout 120s
