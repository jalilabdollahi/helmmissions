#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Prove the scenario is broken: the dependency is declared but nothing was ever fetched into charts/.
[ ! -e "$SANDBOX/storefront/charts" ] || { echo "setup: charts/ already exists"; exit 1; }
if helm install storefront "$SANDBOX/storefront" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: the broken chart installed successfully — scenario is not broken"
  exit 1
fi
grep -q "missing in charts/ directory: session-cache" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
[ -z "$(hm_release_status storefront)" ] || { echo "setup: a release record exists"; exit 1; }
