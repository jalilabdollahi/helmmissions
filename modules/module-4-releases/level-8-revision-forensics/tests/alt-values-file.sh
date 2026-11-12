#!/bin/bash
# Valid alternative: dump the current user values, fix one, and upgrade from the file.
set -euo pipefail
source "$HM_LIB"

helm get values product-search -n "$NS" -o yaml > "$SANDBOX/prod-values.yaml"
sed -i.bak 's/search: false/search: true/' "$SANDBOX/prod-values.yaml"
helm upgrade product-search ./product-search -n "$NS" -f "$SANDBOX/prod-values.yaml" --wait --timeout 90s
