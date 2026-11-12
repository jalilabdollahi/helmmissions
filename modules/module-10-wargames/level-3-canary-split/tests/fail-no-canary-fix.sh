#!/bin/bash
# Partial fix: stable scaled correctly via the file, but the canary values are left as they were.
set -euo pipefail
source "$HM_LIB"
perl -pi -e 's/replicaCount: 1/replicaCount: 9/' "$SANDBOX/values-stable.yaml"
helm upgrade catalog-stable "$SANDBOX/catalog" -n "$NS" -f "$SANDBOX/values-stable.yaml" --wait --timeout 90s
