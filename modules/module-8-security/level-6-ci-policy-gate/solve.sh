#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
bash ci/policy.sh
helm upgrade --install report-worker ./report-worker -n "$NS" --wait --timeout 120s
