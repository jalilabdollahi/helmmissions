#!/bin/bash
set -euo pipefail
source "$HM_LIB"

kubectl create secret docker-registry regcred -n "$NS" \
  --docker-server=localhost:5002 --docker-username=depot --docker-password='Ship-It-2026' >/dev/null
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade portal ./partner-portal -n "$NS" --wait --timeout 120s
