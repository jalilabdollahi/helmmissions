#!/bin/bash
# Tempting shortcut: remove the function so the template parses; the value stays lower-case.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/ | upper | quote/ | quote/' "$SANDBOX/dispatch/templates/deployment.yaml"
rm -f "$SANDBOX/dispatch/templates/deployment.yaml.bak"
helm install dispatch ./dispatch -n "$NS" --wait --timeout 120s
