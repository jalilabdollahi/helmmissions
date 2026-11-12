#!/bin/bash
# Wrong fix: repository added as hm-platform, but Chart.yaml still says @hm-stable; the update keeps failing,
# so nothing gets resolved or deployed.
set -euo pipefail
source "$HM_LIB"

helm repo add hm-platform "$HM_CHARTREPO_URL/m6-repo-not-added" >/dev/null
helm dependency update ./statuspage || true
