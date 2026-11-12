#!/bin/bash
set -euo pipefail
source "$HM_LIB"

C="$SANDBOX/product-search"
# A year of "quick config tweaks". All upgrades use --reuse-values, like the team's wrapper script did.
helm install product-search "$C" -n "$NS" --set features.recommend=false --wait --timeout 90s >/dev/null
helm upgrade product-search "$C" -n "$NS" --reuse-values --set replicaCount=2 >/dev/null
helm upgrade product-search "$C" -n "$NS" --reuse-values --set features.search=false >/dev/null   # the mistake
helm upgrade product-search "$C" -n "$NS" --reuse-values --set cache.ttlSeconds=600 >/dev/null
helm upgrade product-search "$C" -n "$NS" --reuse-values --set logLevel=warn --wait --timeout 90s >/dev/null

[ "$(hm_release_revision product-search)" = "5" ] || { echo "setup: expected 5 revisions"; exit 1; }
[ "$(hm_jsonpath configmap/product-search-config '{.data.FEATURE_SEARCH}')" = "false" ] || { echo "setup: search not disabled"; exit 1; }
