#!/bin/bash
# Valid alternative: a draft 2020-12 schema using $defs, plus the corrected values file.
set -euo pipefail
source "$HM_LIB"

cat > queue-worker/values.schema.json <<'J'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "quantity": { "type": ["string", "number"] },
    "resourceSet": {
      "type": "object",
      "additionalProperties": false,
      "properties": { "cpu": { "$ref": "#/$defs/quantity" }, "memory": { "$ref": "#/$defs/quantity" } }
    }
  },
  "type": "object",
  "additionalProperties": false,
  "required": ["replicaCount"],
  "properties": {
    "replicaCount": { "type": "integer" },
    "image": {
      "type": "object",
      "additionalProperties": false,
      "properties": { "repository": { "type": "string" }, "tag": { "type": "string" }, "pullPolicy": { "type": "string" } }
    },
    "concurrency": { "type": "integer" },
    "resources": {
      "type": "object",
      "additionalProperties": false,
      "properties": { "requests": { "$ref": "#/$defs/resourceSet" }, "limits": { "$ref": "#/$defs/resourceSet" } }
    },
    "probes": {
      "type": "object",
      "additionalProperties": false,
      "properties": { "readiness": { "type": "object", "additionalProperties": false, "properties": { "initialDelaySeconds": { "type": "integer" }, "periodSeconds": { "type": "integer" } } } }
    },
    "extraEnv": { "type": "object" },
    "podAnnotations": { "type": "object" }
  }
}
J
sed -i.bak 's/replicaCnt/replicaCount/; s/periodSecond:/periodSeconds:/' values-prod.yaml && rm values-prod.yaml.bak
helm upgrade queue-worker ./queue-worker -n "$NS" -f values-prod.yaml --wait --timeout 120s
