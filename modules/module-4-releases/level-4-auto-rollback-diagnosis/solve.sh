#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
if [ "$(hm_helm_major)" -ge 4 ]; then flag=--rollback-on-failure; else flag=--atomic; fi
helm upgrade telemetry-gw ./telemetry-gw -n "$NS" "$flag" --timeout 120s
