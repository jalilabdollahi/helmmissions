#!/bin/bash
# Valid alternative: merge without --url (the new entry gets a relative URL, which Helm resolves against the repo URL).
set -euo pipefail
source "$HM_LIB"

URL="$HM_CHARTREPO_URL/m9-repo-index-stale"
helm repo index repo --merge repo/index.yaml
for _ in $(seq 1 20); do curl -fsS "$URL/index.yaml" | grep -q "1.3.0" && break; sleep 1; done
helm repo update hm-tides
helm upgrade tide-tracker hm-tides/tide-tracker --version 1.3.0 -n "$NS" --wait --timeout 120s
