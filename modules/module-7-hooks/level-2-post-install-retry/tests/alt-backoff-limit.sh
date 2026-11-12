#!/bin/bash
# Valid alternative: let the Job retry instead of failing on the first connection error.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/backoffLimit: 0/backoffLimit: 4/' "$SANDBOX/payments-gateway/templates/smoke-test-job.yaml"
rm -f "$SANDBOX/payments-gateway/templates/smoke-test-job.yaml.bak"
bash "$SANDBOX/ci/deploy.sh"
