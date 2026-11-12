#!/bin/bash
# Wrong fix: a pull secret exists, but it was created for a different registry host.
set -euo pipefail
source "$HM_LIB"

kubectl create secret docker-registry regcred -n "$NS" \
  --docker-server=registry.example.com --docker-username=depot --docker-password='Ship-It-2026' >/dev/null
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade portal ./partner-portal -n "$NS" --timeout 40s || true
