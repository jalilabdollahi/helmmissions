#!/bin/bash
# Partial fix: only the downstream tiers are repaired; the failed database release is left alone.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/ledger-api/." "$SANDBOX/ledger-api/"
cp -R "$LEVEL_DIR/solution/ledger-web/." "$SANDBOX/ledger-web/"
helm upgrade ledger-api "$SANDBOX/ledger-api" -n "$NS" --wait --timeout 20s || true
helm upgrade ledger-web "$SANDBOX/ledger-web" -n "$NS" --wait --timeout 60s || true
