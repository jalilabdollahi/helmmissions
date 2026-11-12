#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Release 1 installs cleanly and leaves its rate-check Job behind; the next upgrade collides with it.
helm install tax-engine "$SANDBOX/tax-engine" -n "$NS" --wait --timeout 90s >/dev/null
hm_assert_status tax-engine deployed
helm upgrade tax-engine "$SANDBOX/tax-engine" -n "$NS" --timeout 60s >"$HM_TMP/up.txt" 2>&1 && { echo "setup: upgrade succeeded — scenario not broken"; exit 1; }
grep -Eq 'already exists|immutable' "$HM_TMP/up.txt" || { cat "$HM_TMP/up.txt"; echo "setup: upgrade did not fail on the leftover hook Job"; exit 1; }
hm_assert_status tax-engine failed
