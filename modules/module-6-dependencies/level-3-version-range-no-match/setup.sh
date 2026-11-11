#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Publish redis-lite 1.2.0 / 1.2.3 / 1.2.4 (and nothing newer) in a private classic chart repo.
repo=m6-version-range-no-match
dir="$(hm_chartrepo_path "$repo")"
find "$dir" -maxdepth 1 -name '*.tgz' -delete
for v in 1.2.0 1.2.3 1.2.4; do
  helm package "$LEVEL_DIR/assets/redis-lite" --version "$v" -d "$dir" >/dev/null
done
helm repo index "$dir" --url "$HM_CHARTREPO_URL/$repo"
for _ in $(seq 1 20); do   # the bind-mounted repo directory can take a moment to show the new index
  curl -fsS "$HM_CHARTREPO_URL/$repo/index.yaml" 2>/dev/null | grep -q "1.2.4" && break
  sleep 1
done
curl -fsS "$HM_CHARTREPO_URL/$repo/index.yaml" | grep -q "1.2.4" || { echo "setup: repo not served"; exit 1; }

if helm dependency update "$SANDBOX/searchdesk" >"$HM_TMP/dep.txt" 2>&1; then
  echo "setup: dependency update succeeded — scenario is not broken"; exit 1
fi
grep -q "can't get a valid version" "$HM_TMP/dep.txt" || { cat "$HM_TMP/dep.txt"; exit 1; }
