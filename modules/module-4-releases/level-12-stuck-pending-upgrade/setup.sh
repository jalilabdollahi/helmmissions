#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install warehouse-stock "$LEVEL_DIR/assets/v1/warehouse-stock" -n "$NS" --wait --timeout 90s >/dev/null

# The 1.1 deploy, with a slow pre-upgrade hook, killed mid-flight like an OOM-killed CI runner.
helm upgrade warehouse-stock "$LEVEL_DIR/assets/v2-hook/warehouse-stock" -n "$NS" --wait --timeout 10m >"$HM_TMP/slow.txt" 2>&1 &
pid=$!
for _ in $(seq 1 60); do
  [ "$(hm_release_status warehouse-stock)" = "pending-upgrade" ] && break
  sleep 1
done
kill -9 "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
kubectl delete job warehouse-stock-presync -n "$NS" --now --ignore-not-found >/dev/null 2>&1 || true

[ "$(hm_release_status warehouse-stock)" = "pending-upgrade" ] || { echo "setup: release is not pending-upgrade"; exit 1; }
helm upgrade warehouse-stock "$SANDBOX/warehouse-stock" -n "$NS" >"$HM_TMP/try.txt" 2>&1 && { echo "setup: upgrade succeeded"; exit 1; }
grep -q "another operation (install/upgrade/rollback) is in progress" "$HM_TMP/try.txt" || { cat "$HM_TMP/try.txt"; exit 1; }
