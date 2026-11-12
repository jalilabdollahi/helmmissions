#!/bin/bash
# Tempting wrong fix: retry the rollback (maybe it was a blip) and clear the failed hook Job.
set -euo pipefail
source "$HM_LIB"

kubectl delete job settlement-batch-drain -n "$NS" --ignore-not-found
helm rollback settlement-batch 1 -n "$NS" --timeout 60s || true
