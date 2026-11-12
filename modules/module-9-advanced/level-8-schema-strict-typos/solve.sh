#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/queue-worker/values.schema.json" queue-worker/values.schema.json
if helm template queue-worker ./queue-worker -f values-prod.yaml >/dev/null 2>&1; then echo "expected the schema to catch the typos"; exit 1; fi
cp "$LEVEL_DIR/solution/values-prod.yaml" values-prod.yaml
helm upgrade queue-worker ./queue-worker -n "$NS" -f values-prod.yaml --wait --timeout 120s
