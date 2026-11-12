#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install checkout "$LEVEL_DIR/assets/checkout" -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status checkout deployed

# What the player would see first: the documented install command fails ...
if helm plugin install "$SANDBOX/hm-audit" >"$HM_TMP/plugin.txt" 2>&1; then
  echo "setup: plugin installed cleanly — scenario is not broken"; exit 1
fi
grep -q 'install-rules.sh: no such file' "$HM_TMP/plugin.txt" || { cat "$HM_TMP/plugin.txt"; exit 1; }
# ... and leaves a half-installed plugin whose command is broken as well.
helm plugin list | grep -q '^hm-audit' || { echo "setup: expected the half-installed plugin to be listed"; exit 1; }
if helm hm-audit checkout -n "$NS" >"$HM_TMP/run.txt" 2>&1; then
  echo "setup: helm hm-audit works — scenario is not broken"; exit 1
fi
grep -q 'audit.sh: no such file' "$HM_TMP/run.txt" || { cat "$HM_TMP/run.txt"; exit 1; }
