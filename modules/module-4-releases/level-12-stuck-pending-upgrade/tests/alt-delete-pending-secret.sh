#!/bin/bash
# Valid alternative: remove the interrupted revision's release Secret by hand, then upgrade again.
set -euo pipefail
source "$HM_LIB"

kubectl delete secret sh.helm.release.v1.warehouse-stock.v2 -n "$NS"
helm upgrade warehouse-stock ./warehouse-stock -n "$NS" --wait --timeout 120s
