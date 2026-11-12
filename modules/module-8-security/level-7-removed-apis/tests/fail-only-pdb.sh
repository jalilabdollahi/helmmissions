#!/bin/bash
# Partial fix: the PodDisruptionBudget is migrated, the HPA still uses the removed API -> install still fails.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's#policy/v1beta1#policy/v1#' inventory-service/templates/pdb.yaml && rm -f inventory-service/templates/pdb.yaml.bak
helm upgrade --install inventory ./inventory-service -n "$NS" --wait --timeout 60s || true
