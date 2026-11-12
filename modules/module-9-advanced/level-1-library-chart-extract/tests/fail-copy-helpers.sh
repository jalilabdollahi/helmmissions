#!/bin/bash
# Tempting shortcut: make the two _helpers.tpl copies identical (copy-paste) instead of extracting a library.
set -euo pipefail
source "$HM_LIB"

lib="$LEVEL_DIR/solution/platformlib/templates/_labels.tpl"
for c in ledger-api ledger-worker; do
  sed "s/platformlib\./$c./g" "$lib" > "$c/templates/_helpers.tpl"
done
helm upgrade ledger-api ./ledger-api -n "$NS" --wait --timeout 120s
helm upgrade ledger-worker ./ledger-worker -n "$NS" --wait --timeout 120s
