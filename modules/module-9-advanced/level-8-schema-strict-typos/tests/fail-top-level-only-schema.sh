#!/bin/bash
# Partial fix: a schema that is strict only at the top level; typos below image/resources still pass.
set -euo pipefail
source "$HM_LIB"

cat > queue-worker/values.schema.json <<'J'
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "replicaCount": { "type": "integer" },
    "image": { "type": "object" },
    "concurrency": { "type": "integer" },
    "resources": { "type": "object" },
    "probes": { "type": "object" },
    "extraEnv": { "type": "object" },
    "podAnnotations": { "type": "object" }
  }
}
J
cp "$LEVEL_DIR/solution/values-prod.yaml" values-prod.yaml
helm upgrade queue-worker ./queue-worker -n "$NS" -f values-prod.yaml --wait --timeout 120s
