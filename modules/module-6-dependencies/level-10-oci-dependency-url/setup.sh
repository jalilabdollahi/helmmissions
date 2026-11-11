#!/bin/bash
set -euo pipefail
source "$HM_LIB"
hm_registry_up

# Publish seat-cache 2.0.1 at oci://localhost:5001/m6-oci-dependency-url/charts/seat-cache:2.0.1
helm package "$LEVEL_DIR/assets/seat-cache" -d "$HM_TMP" >/dev/null
helm push "$HM_TMP/seat-cache-2.0.1.tgz" "oci://$HM_REGISTRY/m6-oci-dependency-url/charts" --plain-http >/dev/null

if helm dependency update "$SANDBOX/booking" --plain-http >"$HM_TMP/dep.txt" 2>&1; then
  echo "setup: dependency update succeeded — scenario is not broken"; exit 1
fi
grep -q "seat-cache/seat-cache" "$HM_TMP/dep.txt" && grep -qi "not found" "$HM_TMP/dep.txt" || { cat "$HM_TMP/dep.txt"; exit 1; }
