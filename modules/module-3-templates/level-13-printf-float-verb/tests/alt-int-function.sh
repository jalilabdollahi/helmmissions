#!/bin/bash
# Alternative: keep %d but convert the value to an integer first.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/{{ printf "%v" .Values.port }}/{{ printf "%d" (int .Values.port) }}/' "$SANDBOX/ingest/templates/deployment.yaml"
rm -f "$SANDBOX/ingest/templates/deployment.yaml.bak"
helm upgrade ingest ./ingest -n "$NS" --wait --timeout 120s
