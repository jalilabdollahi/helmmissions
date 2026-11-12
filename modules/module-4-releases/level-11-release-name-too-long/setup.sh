#!/bin/bash
set -euo pipefail
source "$HM_LIB"

REL=customer-notification-dispatcher-production-eu
helm install "$REL" "$SANDBOX/notification-dispatcher" -n "$NS" --timeout 60s >"$HM_TMP/install.txt" 2>&1 && { echo "setup: install succeeded"; exit 1; }
grep -q "must be no more than 63 characters" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
