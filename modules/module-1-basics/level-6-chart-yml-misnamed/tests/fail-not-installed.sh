#!/bin/bash
# Renames the file but never installs.
set -euo pipefail
source "$HM_LIB"

mv "$SANDBOX/status-page/Chart.yml" "$SANDBOX/status-page/Chart.yaml"
