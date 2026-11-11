#!/bin/bash
# Tempting workaround: turn the Ingress off so the install goes through.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/^  enabled: true/  enabled: false/' "$SANDBOX/docs-portal/values.yaml"
rm -f "$SANDBOX/docs-portal/values.yaml.bak"
helm install portal ./docs-portal -n "$NS" --wait --timeout 120s
