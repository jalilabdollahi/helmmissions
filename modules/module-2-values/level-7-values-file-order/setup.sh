#!/bin/bash
set -euo pipefail
source "$HM_LIB"

bash "$SANDBOX/deploy.sh" >/dev/null
r="$(kubectl get deploy checkout -n helmissions-prod -o jsonpath='{.spec.replicas}')"
[ "$r" = "1" ] || { echo "setup: expected 1 replica from the wrong merge order, got $r"; exit 1; }
