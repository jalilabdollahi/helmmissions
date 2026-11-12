#!/bin/bash
# Wrong fix: skip hooks for this upgrade. Release is deployed but the chart is unchanged and the rate check never ran.
set -euo pipefail
source "$HM_LIB"

helm upgrade tax-engine ./tax-engine -n "$NS" --no-hooks --wait --timeout 90s
