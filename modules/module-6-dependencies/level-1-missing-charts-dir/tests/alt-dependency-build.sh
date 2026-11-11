#!/bin/bash
# Valid alternative: `helm dependency build` (no lock file yet, so it resolves like update) then install.
set -euo pipefail
source "$HM_LIB"

helm dependency build ./storefront
helm install storefront ./storefront -n "$NS" --wait --timeout 120s
