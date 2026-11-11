#!/bin/bash
# Valid alternative: fix the path, then `build` (no lock yet) instead of `update`.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's#charts/seat-cache$#charts#' booking/Chart.yaml && rm -f booking/Chart.yaml.bak
helm dependency build ./booking --plain-http
helm install booking ./booking -n "$NS" --wait --timeout 120s
