#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Return the release to its last good revision, then redo the upgrade the pipeline was attempting.
helm rollback warehouse-stock 1 -n "$NS" --wait --timeout 90s
helm upgrade warehouse-stock ./warehouse-stock -n "$NS" --wait --timeout 120s
