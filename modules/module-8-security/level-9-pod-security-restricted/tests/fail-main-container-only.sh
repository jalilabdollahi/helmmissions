#!/bin/bash
# Partial fix: the gateway container is hardened through values, the init container is forgotten.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cp "$LEVEL_DIR/broken/audit-gateway/templates/deployment.yaml" audit-gateway/templates/deployment.yaml
helm upgrade audit-gateway ./audit-gateway -n "$NS" --timeout 30s || true
sleep 5
