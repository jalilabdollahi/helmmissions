#!/bin/bash
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
# prod already ran the previous build, healthy
helm install billing ./billing -n "$NS" -f values/prod.yaml --set image.tag=1.36 --wait --timeout 60s >/dev/null
# last night's run: staging values were never committed, the script did not stop, and prod got an empty tag
bash pipeline.sh >"$HM_TMP/last-night.txt" 2>&1 || true
hm_assert_status billing failed
hm_assert_status billing-dev deployed helmissions-dev
[ -z "$(hm_release_status billing-staging helmissions-staging)" ] || { echo "setup: staging should not exist"; exit 1; }
grep -q "staging.yaml" "$HM_TMP/last-night.txt" || { echo "setup: expected the missing staging file error"; cat "$HM_TMP/last-night.txt"; exit 1; }
kubectl get pods -n "$NS" --no-headers | grep -qE 'InvalidImageName|ErrImage|ImagePull' || { echo "setup: expected a pod with a bad image"; kubectl get pods -n "$NS"; exit 1; }
