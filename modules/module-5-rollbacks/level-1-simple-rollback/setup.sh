#!/bin/bash
set -euo pipefail
source "$HM_LIB"

CHART="$LEVEL_DIR/assets/quotes-api"
helm install quotes-api "$CHART" -n "$NS" --wait --timeout 90s >/dev/null
# Friday's deploy: bumped the tag to one that was never published. No --wait, so the pipeline stayed green.
helm upgrade quotes-api "$CHART" -n "$NS" --set image.tag=v1.10.1-rc1 >/dev/null

hm_assert_status quotes-api deployed
[ "$(hm_release_revision quotes-api)" = "2" ] || { echo "setup: expected revision 2"; exit 1; }
for _ in $(seq 1 30); do
  reason="$(kubectl get pods -n "$NS" -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' 2>/dev/null || true)"
  case "$reason" in *ErrImagePull*|*ImagePullBackOff*) break ;; esac
  sleep 2
done
case "$reason" in *ErrImagePull*|*ImagePullBackOff*) ;; *) echo "setup: pod is not failing to pull"; exit 1 ;; esac
