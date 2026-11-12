#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The CI gate must be red for the shipped chart, with both errors and warnings.
if bash "$SANDBOX/ci/lint.sh" >"$HM_TMP/lint.txt" 2>&1; then
  echo "setup: lint --strict passed - scenario is not broken"; exit 1
fi
grep -q "\[ERROR\]" "$HM_TMP/lint.txt" && grep -q "\[WARNING\]" "$HM_TMP/lint.txt" || { cat "$HM_TMP/lint.txt"; exit 1; }
# Plain lint (errors only) must also fail, so the player sees why --strict matters later.
