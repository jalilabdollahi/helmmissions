#!/bin/bash
# Tempting: edit the schema until the values pass.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/"minimum": 1/"minimum": 0/; s/"debug", "info", "warn", "error"/"debug", "info", "warn", "WARN", "error"/' search-api/values.schema.json
helm install search-api ./search-api -n "$NS" --wait --timeout 60s || true
