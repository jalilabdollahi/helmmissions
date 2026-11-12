#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade tenants ./tenant-onboarding -n "$NS" --wait --timeout 90s
