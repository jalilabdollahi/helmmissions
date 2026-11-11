#!/bin/bash
# Copies instead of renaming: a stray Chart.yml stays in the chart.
set -euo pipefail
source "$HM_LIB"

cp "$SANDBOX/status-page/Chart.yml" "$SANDBOX/status-page/Chart.yaml"
helm install status-page ./status-page -n "$NS" --wait --timeout 120s
