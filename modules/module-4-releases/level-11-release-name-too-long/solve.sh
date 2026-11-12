#!/bin/bash
set -euo pipefail
source "$HM_LIB"

REL=customer-notification-dispatcher-production-eu
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
if [ -n "$(helm status "$REL" -n "$NS" -o json 2>/dev/null || true)" ]; then verb=upgrade; else verb=install; fi
helm "$verb" "$REL" ./notification-dispatcher -n "$NS" --wait --timeout 120s
