#!/bin/bash
# Tempting wrong fix: delete the StatefulSet so Helm re-creates it with the new volumeClaimTemplate.
# Data survives, but the template (and the volume contract) is changed, and the existing PVC stays 1Gi anyway.
set -euo pipefail
source "$HM_LIB"

kubectl delete statefulset tsdb -n "$NS" --wait=true
helm upgrade tsdb ./timeseries-db -n "$NS" --wait --timeout 120s
