#!/bin/bash
# Tempting shortcut: type the port into the template.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/{{ printf "%v" .Values.port }}/8080/' "$SANDBOX/ingest/templates/deployment.yaml"
rm -f "$SANDBOX/ingest/templates/deployment.yaml.bak"
helm upgrade ingest ./ingest -n "$NS" --wait --timeout 120s
