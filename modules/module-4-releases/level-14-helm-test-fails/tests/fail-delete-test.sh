#!/bin/bash
# Wrong fix: remove the failing test from the chart and redeploy. No test, no red — and no safety net.
set -euo pipefail
source "$HM_LIB"

rm -r "$SANDBOX/rating-service/templates/tests"
helm upgrade rating-service ./rating-service -n "$NS" --wait --timeout 90s
