#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install payroll "$SANDBOX/payroll-api" -n "$NS" --timeout 40s >"$HM_TMP/install.txt" 2>&1 && { echo "setup: install succeeded — scenario not broken"; exit 1; }
hm_assert_status payroll failed
kubectl get pods -n "$NS" -l app.kubernetes.io/component=db-bootstrap -o json | jq -e '[.items[].status.containerStatuses[]?.state.waiting.reason] | any(. == "CreateContainerConfigError")' >/dev/null \
  || { echo "setup: the bootstrap pod is not stuck on the missing Secret"; exit 1; }
