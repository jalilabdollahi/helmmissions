#!/bin/bash
# Partial fix: the chart is fixed and team-b installed, but team-a is left running on the old shared names.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm install team-b "$SANDBOX/collector" -n helmissions-team-b -f "$SANDBOX/values/team-b.yaml" --wait --timeout 90s
