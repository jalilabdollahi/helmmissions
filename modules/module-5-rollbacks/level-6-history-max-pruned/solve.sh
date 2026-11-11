#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# revision 1 is gone: restore the known-good configuration from the chart defaults and redeploy
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
bash ci/deploy.sh
