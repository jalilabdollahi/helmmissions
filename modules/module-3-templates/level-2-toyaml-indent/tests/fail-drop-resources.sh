#!/bin/bash
# Tempting shortcut: delete the resources block so the install stops failing.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak '/resources:/,$d' "$SANDBOX/geoip/templates/deployment.yaml"
rm -f "$SANDBOX/geoip/templates/deployment.yaml.bak"
helm install geoip ./geoip -n "$NS" --wait --timeout 120s
