#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install upload-proxy "$SANDBOX/upload-proxy" -n "$NS" >/dev/null
v="$(kubectl get configmap upload-proxy-limits -n "$NS" -o jsonpath='{.data.MAX_UPLOAD_BYTES}')"
[ "$v" = "1.048576e+06" ] || { echo "setup: expected scientific notation, got '$v'"; exit 1; }
