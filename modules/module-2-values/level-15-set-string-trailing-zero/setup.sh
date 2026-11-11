#!/bin/bash
set -euo pipefail
source "$HM_LIB"

bash "$SANDBOX/deploy.sh" >/dev/null
v="$(kubectl get deploy status-page -n "$NS" -o jsonpath='{.spec.template.metadata.labels.app\.version}')"
[ "$v" = "1.1" ] || { echo "setup: expected the label to read 1.1, got '$v'"; exit 1; }
