#!/bin/bash
# Valid alternative: run the three commands by hand with a different package directory.
set -euo pipefail
source "$HM_LIB"

BASE="$(cat .hm-registry-base)"
helm package payments-gateway -d "$HM_TMP/pkg"
helm push "$HM_TMP/pkg/payments-gateway-0.3.0.tgz" "oci://localhost:5001/$BASE/charts" --plain-http
helm upgrade payments-gateway "oci://localhost:5001/$BASE/charts/payments-gateway" --version 0.3.0 --plain-http \
  -n "$NS" --wait --timeout 120s
