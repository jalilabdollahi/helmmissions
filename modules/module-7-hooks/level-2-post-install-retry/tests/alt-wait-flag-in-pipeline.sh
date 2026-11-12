#!/bin/bash
# Valid alternative: leave the hook alone, make the pipeline wait for readiness before post-install hooks run.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/--timeout 2m/--wait --timeout 2m/' "$SANDBOX/ci/deploy.sh"
rm -f "$SANDBOX/ci/deploy.sh.bak"
bash "$SANDBOX/ci/deploy.sh"
