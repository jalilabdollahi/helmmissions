#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/values-metrics.yaml" .
helm upgrade telemetry-agent ./telemetry-agent -n "$NS" -f values-metrics.yaml --wait --timeout 120s
