#!/bin/bash
set -euo pipefail
source "$HM_LIB"
hm_registry_up
cd "$SANDBOX"

# The internal chart registry has both cache versions.
for v in 1.1.0 1.2.0; do
  helm package "$LEVEL_DIR/assets/cache-$v" -d "$HM_TMP" >/dev/null
  helm push "$HM_TMP/cache-$v.tgz" "oci://$HM_REGISTRY/m10-final-incident/charts" --plain-http >/dev/null
done

# Staging, deployed this morning from the workspace as it is (stale dependency, prod database host).
bash deploy.sh staging >/dev/null 2>&1
hm_assert_status tideline-staging deployed helmissions-staging

# Prod, revision 1: the previous release, healthy on the old requirements.
helm install tideline ./tideline -n "$NS" -f values/common.yaml -f values/prod.yaml \
  --set schema.target=12 --set minCacheVersion=1.1.0 --set migration.settleSeconds=0 --wait --timeout 90s >/dev/null
hm_assert_status tideline deployed

# Prod, revision 2: the CI run that was killed in the middle of the pre-upgrade hook.
helm upgrade tideline ./tideline -n "$NS" -f values/common.yaml -f values/prod.yaml \
  --set migration.settleSeconds=45 --wait --timeout 120s >/dev/null 2>&1 &
HPID=$!
for _ in $(seq 1 60); do
  st="$(helm history tideline -n "$NS" -o json 2>/dev/null | jq -r '.[-1].status' 2>/dev/null || true)"
  [ "$st" = "pending-upgrade" ] && kubectl get job tideline-migrate -n "$NS" >/dev/null 2>&1 && break
  sleep 1
done
kill -9 "$HPID" 2>/dev/null || true
wait "$HPID" 2>/dev/null || true
sleep 1
hm_assert_status tideline pending-upgrade
helm upgrade tideline ./tideline -n "$NS" -f values/common.yaml -f values/prod.yaml >"$HM_TMP/blocked.txt" 2>&1 && { echo "setup: upgrade was not blocked"; exit 1; }
grep -q "another operation" "$HM_TMP/blocked.txt" || { cat "$HM_TMP/blocked.txt"; exit 1; }
helm dependency list ./tideline | grep -q "wrong version" || { echo "setup: dependency not stale"; exit 1; }
