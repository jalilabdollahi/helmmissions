#!/bin/bash
# Valid alternative: drop the unpacked subchart straight into charts/ (what `helm dependency build` does, minus the tarball).
set -euo pipefail
source "$HM_LIB"

mkdir -p storefront/charts
cp -R session-cache storefront/charts/
helm install storefront ./storefront -n "$NS" --wait --timeout 120s
