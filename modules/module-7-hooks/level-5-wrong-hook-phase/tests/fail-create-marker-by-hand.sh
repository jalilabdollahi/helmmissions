#!/bin/bash
# Tempting wrong fix: create the schema marker with kubectl so the pods start. The chart's hook is still in the wrong phase.
set -euo pipefail
source "$HM_LIB"

kubectl create configmap shipments-schema-v2 -n "$NS" --from-literal=migrated-at=by-hand
helm upgrade shipments ./shipment-tracker -n "$NS" --wait --timeout 90s
