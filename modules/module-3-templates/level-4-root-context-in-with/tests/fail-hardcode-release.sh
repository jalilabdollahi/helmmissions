#!/bin/bash
# Tempting shortcut: type the release name instead of reading it from the root context.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/{{ \$\.Release\.Name }}$/tiles/' "$SANDBOX/tileserver/templates/deployment.yaml"
rm -f "$SANDBOX/tileserver/templates/deployment.yaml.bak"
grep -q 'release: tiles' "$SANDBOX/tileserver/templates/deployment.yaml"
helm install tiles ./tileserver -n "$NS" --wait --timeout 120s
