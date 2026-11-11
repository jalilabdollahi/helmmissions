#!/bin/bash
# Wrong fix: roll back to the oldest revision that is still there - it already has the retired provider.
set -euo pipefail
source "$HM_LIB"

helm rollback geo-lookup 2 -n "$NS" --wait --timeout 60s
