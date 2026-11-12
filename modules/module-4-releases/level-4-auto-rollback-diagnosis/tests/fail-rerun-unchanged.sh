#!/bin/bash
# Wrong fix: run the same atomic upgrade again — it fails and rolls back again.
set -euo pipefail
source "$HM_LIB"

if [ "$(hm_helm_major)" -ge 4 ]; then flag=--rollback-on-failure; else flag=--atomic; fi
helm upgrade telemetry-gw ./telemetry-gw -n "$NS" "$flag" --timeout 60s || true
