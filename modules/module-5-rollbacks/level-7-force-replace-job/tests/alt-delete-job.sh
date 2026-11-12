#!/bin/bash
# Valid alternative: delete the finished Job (Helm re-creates it from the new manifest).
set -euo pipefail
source "$HM_LIB"

kubectl delete job catalog-seed -n "$NS"
helm upgrade catalog ./catalog-seed -n "$NS" --wait --timeout 120s
