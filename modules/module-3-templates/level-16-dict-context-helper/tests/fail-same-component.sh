#!/bin/bash
# Tempting shortcut: pass the same dict everywhere (copy-paste the api call) - both components collide.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/"component" "worker"/"component" "api"/g' "$SANDBOX/mailer/templates/worker.yaml"
rm -f "$SANDBOX/mailer/templates/worker.yaml.bak"
helm install mailer ./mailer -n "$NS" --timeout 30s || true
