#!/bin/bash
set -euo pipefail
source "$HM_LIB"

repo=m9-repo-index-stale
URL="$HM_CHARTREPO_URL/$repo"
dir="$(hm_chartrepo_path "$repo")"
find "${dir:?}" -mindepth 1 -delete
mkdir -p "$dir/archive/legacy"

# 1.1.0 (retired to archive/legacy) and 1.2.0 are in the index; 1.3.0 is just a file.
helm package "$LEVEL_DIR/assets/tide-tracker-old" --version 1.1.0 -d "$dir" >/dev/null
helm package "$LEVEL_DIR/assets/tide-tracker-old" --version 1.2.0 -d "$dir" >/dev/null
helm repo index "$dir" --url "$URL"
mv "$dir/tide-tracker-1.1.0.tgz" "$dir/archive/legacy/"
sed "s#$URL/tide-tracker-1.1.0.tgz#$URL/archive/legacy/tide-tracker-1.1.0.tgz#" "$dir/index.yaml" > "$HM_TMP/index.yaml"
cp "$HM_TMP/index.yaml" "$dir/index.yaml"
helm package "$LEVEL_DIR/assets/tide-tracker-new" -d "$dir" >/dev/null
for _ in $(seq 1 20); do
  curl -fsS "$URL/index.yaml" 2>/dev/null | grep -q "archive/legacy" && break
  sleep 1
done
curl -fsS "$URL/index.yaml" | grep -q "archive/legacy" || { echo "setup: repo not served"; exit 1; }
curl -fsS -o /dev/null "$URL/archive/legacy/tide-tracker-1.1.0.tgz" || { echo "setup: archive not served"; exit 1; }

ln -sfn "$dir" "$SANDBOX/repo"
sed "s#@@URL@@#$URL#" "$SANDBOX/README.txt" > "$HM_TMP/README.txt"
cp "$HM_TMP/README.txt" "$SANDBOX/README.txt"

helm repo add hm-tides "$URL" --force-update >/dev/null
helm repo update hm-tides >/dev/null
helm install tide-tracker hm-tides/tide-tracker --version 1.2.0 -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status tide-tracker deployed
if helm upgrade tide-tracker hm-tides/tide-tracker --version 1.3.0 -n "$NS" --dry-run >"$HM_TMP/up.txt" 2>&1; then
  echo "setup: upgrade to 1.3.0 worked — scenario is not broken"; exit 1
fi
grep -q "not found" "$HM_TMP/up.txt" || { cat "$HM_TMP/up.txt"; exit 1; }
