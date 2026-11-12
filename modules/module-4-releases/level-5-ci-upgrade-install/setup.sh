#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Reproduce the pipeline's first deploy: it must fail and leave no release behind.
if (cd "$SANDBOX" && bash ci/deploy.sh) >"$HM_TMP/deploy.txt" 2>&1; then
  echo "setup: the deploy script succeeded — scenario is not broken"; exit 1
fi
grep -q "has no deployed releases" "$HM_TMP/deploy.txt" || { cat "$HM_TMP/deploy.txt"; exit 1; }
[ -z "$(hm_release_status shipment-tracker)" ] || { echo "setup: a release exists"; exit 1; }
