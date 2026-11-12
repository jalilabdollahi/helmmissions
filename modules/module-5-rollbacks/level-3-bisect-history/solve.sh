#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Inspect what each revision deployed, then go back to the newest healthy one.
for r in 1 2 3 4 5 6; do echo "--- rev $r"; helm get values freight-quote -n "$NS" --revision "$r"; done
helm rollback freight-quote 4 -n "$NS" --wait --timeout 120s
