#!/bin/bash
# Alternative: derive unique Service port names from the port number.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/    - name: {{ .name }}$/    - name: {{ printf "p%d" (int .port) }}/' "$SANDBOX/mesh-edge/templates/service.yaml"
rm -f "$SANDBOX/mesh-edge/templates/service.yaml.bak"
helm install edge ./mesh-edge -n "$NS" --wait --timeout 120s
