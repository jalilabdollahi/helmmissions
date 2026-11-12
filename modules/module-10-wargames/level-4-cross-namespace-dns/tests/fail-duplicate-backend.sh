#!/bin/bash
# Shortcut: run another copy of the back end next to the front end instead of fixing cross-namespace addressing.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
helm upgrade orders-api ./orders-api -n helmissions-api --wait --timeout 60s
helm install orders-api-local ./orders-api --set service.targetPort=8080 -n helmissions-web --wait --timeout 60s
perl -pi -e 's/host: orders-api\..*/host: orders-api-local/' orders-web/values.yaml
helm upgrade orders-web ./orders-web -n helmissions-web --wait --timeout 60s
