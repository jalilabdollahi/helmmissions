#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cd "$SANDBOX"
if bash ci/policy.sh >"$HM_TMP/gate.txt" 2>&1; then echo "setup: the gate passes on the broken chart"; exit 1; fi
grep -q "floating tag" "$HM_TMP/gate.txt" && grep -q "limits" "$HM_TMP/gate.txt" && grep -q "Probe" "$HM_TMP/gate.txt" \
  || { cat "$HM_TMP/gate.txt"; echo "setup: the gate does not report all three rule families"; exit 1; }
[ -z "$(hm_release_status report-worker)" ] || { echo "setup: release already exists"; exit 1; }
