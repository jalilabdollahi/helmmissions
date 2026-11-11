#!/bin/bash
# Valid alternative: add hm-stable, then `build` (no lock yet, so it resolves like update).
set -euo pipefail
source "$HM_LIB"

helm repo add hm-stable "$HM_CHARTREPO_URL/m6-repo-not-added" >/dev/null
helm repo update >/dev/null
helm dependency build ./statuspage
helm install statuspage ./statuspage -n "$NS" --wait --timeout 120s
