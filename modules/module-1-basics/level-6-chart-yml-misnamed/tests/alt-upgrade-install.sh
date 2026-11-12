#!/bin/bash
set -euo pipefail
source "$HM_LIB"

mv "$SANDBOX/status-page/Chart.yml" "$SANDBOX/status-page/Chart.yaml"
helm upgrade --install status-page ./status-page -n "$NS" --wait --timeout 120s
