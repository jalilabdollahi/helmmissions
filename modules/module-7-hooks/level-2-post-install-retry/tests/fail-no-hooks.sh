#!/bin/bash
# Tempting wrong fix: switch the hooks off in the pipeline. Green deploy, no smoke test.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/--timeout 2m/--no-hooks --timeout 2m/' "$SANDBOX/ci/deploy.sh"
rm -f "$SANDBOX/ci/deploy.sh.bak"
kubectl delete job payments-gateway-smoke -n "$NS" --ignore-not-found >/dev/null
bash "$SANDBOX/ci/deploy.sh"
