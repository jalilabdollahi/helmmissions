#!/bin/bash
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
bash deploy.sh dev >/dev/null 2>&1
bash deploy.sh prod >/dev/null 2>&1
hm_assert_status invoice-dev deployed helmissions-dev
hm_assert_status invoice deployed
hm_http_check http://invoice/config.txt >"$HM_TMP/c.txt" || { echo "setup: prod config page unreachable"; exit 1; }
grep -q "environment=dev" "$HM_TMP/c.txt" && grep -q "payments=sandbox" "$HM_TMP/c.txt" || { echo "setup: prod does not carry dev values"; cat "$HM_TMP/c.txt"; exit 1; }
