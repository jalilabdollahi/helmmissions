#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Publish uptime-probe 1.4.0 (and an older 1.3.2) in the platform team's repository.
repo=m6-repo-not-added
dir="$(hm_chartrepo_path "$repo")"
find "$dir" -maxdepth 1 -name '*.tgz' -delete
for v in 1.3.2 1.4.0; do
  helm package "$LEVEL_DIR/assets/uptime-probe" --version "$v" -d "$dir" >/dev/null
done
helm repo index "$dir" --url "$HM_CHARTREPO_URL/$repo"
for _ in $(seq 1 20); do   # the bind-mounted repo directory can take a moment to show the new index
  curl -fsS "$HM_CHARTREPO_URL/$repo/index.yaml" 2>/dev/null | grep -q "1.4.0" && break
  sleep 1
done
curl -fsS "$HM_CHARTREPO_URL/$repo/index.yaml" | grep -q "1.4.0" || { echo "setup: repo not served"; exit 1; }

# The workstation has no repository called hm-stable.
helm repo remove hm-stable >/dev/null 2>&1 || true
if helm dependency update "$SANDBOX/statuspage" >"$HM_TMP/dep.txt" 2>&1; then
  echo "setup: dependency update succeeded — scenario is not broken"; exit 1
fi
grep -q "no repository definition for @hm-stable" "$HM_TMP/dep.txt" || { cat "$HM_TMP/dep.txt"; exit 1; }
