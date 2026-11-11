#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The same subchart is listed twice with no alias: Helm refuses to even load the chart.
if helm install inventory "$SANDBOX/inventory" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: install succeeded — scenario is not broken"; exit 1
fi
grep -q 'more than one dependency with name or alias "kvstore"' "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
[ -z "$(hm_release_status inventory)" ] || { echo "setup: a release record exists"; exit 1; }
