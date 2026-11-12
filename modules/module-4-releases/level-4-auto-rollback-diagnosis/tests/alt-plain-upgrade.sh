#!/bin/bash
# Valid alternative: fix the schedule and upgrade without the atomic flag.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade telemetry-gw ./telemetry-gw -n "$NS" --wait --timeout 120s
