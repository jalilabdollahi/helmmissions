#!/bin/bash
# Wrong fix: install under a shorter release name. The required name still does not exist.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm install cust-notif-prod-eu ./notification-dispatcher -n "$NS" --wait --timeout 90s
