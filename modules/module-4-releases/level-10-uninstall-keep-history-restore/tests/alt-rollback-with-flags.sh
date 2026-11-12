#!/bin/bash
# Valid alternative: same rollback, spelled with extra safety flags and a status check first.
set -euo pipefail
source "$HM_LIB"

helm list -n "$NS" --uninstalled >/dev/null
helm rollback loyalty-points 2 -n "$NS" --cleanup-on-fail --timeout 120s --wait
