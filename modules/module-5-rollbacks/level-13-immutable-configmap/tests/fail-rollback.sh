#!/bin/bash
# Wrong fix: roll back - flags stay at their old value and the chart is still unfixed.
set -euo pipefail
source "$HM_LIB"

helm rollback flags 1 -n "$NS" --wait --timeout 90s
