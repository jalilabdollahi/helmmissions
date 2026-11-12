#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm install profile-svc ./profile-svc -n "$NS" -f values-staging.yaml --wait --timeout 120s
