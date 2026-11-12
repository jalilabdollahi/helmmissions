#!/bin/bash
# Tempting wrong fix: `helm rollback` without a revision goes to "the previous revision" = 1,
# an older chart and different values than the last live state.
set -euo pipefail
source "$HM_LIB"

helm rollback loyalty-points -n "$NS" --wait --timeout 90s
