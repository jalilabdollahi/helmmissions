#!/bin/bash
# Tempting wrong fix: delete the leftover Job and upgrade. Works once; the chart still collides next time.
set -euo pipefail
source "$HM_LIB"

kubectl delete job tax-engine-rate-check -n "$NS"
helm upgrade tax-engine ./tax-engine -n "$NS" --wait --timeout 90s
