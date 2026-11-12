#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The pipeline's first deploy: the smoke test fires before the gateway is ready and fails the release.
bash "$SANDBOX/ci/deploy.sh" >"$HM_TMP/deploy.txt" 2>&1 && { echo "setup: deploy succeeded — scenario not broken"; exit 1; }
hm_assert_status payments-gateway failed
grep -q "failed post-install" "$HM_TMP/deploy.txt" || { cat "$HM_TMP/deploy.txt"; echo "setup: deploy did not fail in the post-install phase"; exit 1; }
kubectl logs job/payments-gateway-smoke -n "$NS" 2>&1 | grep -q "Failed to connect" || { echo "setup: smoke test did not fail with a connection error"; exit 1; }
