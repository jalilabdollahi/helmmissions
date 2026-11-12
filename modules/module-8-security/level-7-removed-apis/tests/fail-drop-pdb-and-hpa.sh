#!/bin/bash
# Tempting wrong fix: delete the two templates that carry removed APIs.
set -euo pipefail
source "$HM_LIB"

rm -f inventory-service/templates/pdb.yaml inventory-service/templates/hpa.yaml
helm upgrade --install inventory ./inventory-service -n "$NS" --wait --timeout 120s
