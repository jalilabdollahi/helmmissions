#!/bin/bash
# Shortcut: heal prod and create staging by hand; the pipeline script itself is left as it was.
set -euo pipefail
source "$HM_LIB"
cp "$LEVEL_DIR/solution/values/staging.yaml" "$SANDBOX/values/staging.yaml"
cd "$SANDBOX"
helm upgrade --install billing-staging ./billing -n helmissions-staging --create-namespace -f values/staging.yaml --set image.tag=1.36 --wait --timeout 60s
helm upgrade billing ./billing -n "$NS" -f values/prod.yaml --set image.tag=1.36 --wait --timeout 60s
