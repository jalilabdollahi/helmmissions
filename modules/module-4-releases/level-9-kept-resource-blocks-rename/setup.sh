#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The old release, installed and then uninstalled. The Secret survives because of resource-policy: keep.
helm install shop "$LEVEL_DIR/assets/shop" -n "$NS" --wait --timeout 90s >/dev/null
helm uninstall shop -n "$NS" >/dev/null
[ -z "$(hm_release_status shop)" ] || { echo "setup: release shop still exists"; exit 1; }
[ "$(hm_jsonpath secret/db-credentials '{.metadata.annotations.meta\.helm\.sh/release-name}')" = "shop" ] \
  || { echo "setup: the kept Secret is missing"; exit 1; }

if helm install storefront "$SANDBOX/storefront" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: install succeeded — scenario is not broken"; exit 1
fi
grep -q 'current value is "shop"' "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
[ -z "$(hm_release_status storefront)" ] || { echo "setup: a storefront release exists"; exit 1; }
