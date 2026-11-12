#!/bin/bash
set -euo pipefail
source "$HM_LIB"
hm_registry_up

# The shared registry cannot delete artifacts, so every run publishes under its own base path.
BASE="m9-oci-push-install/r$(date +%s)"
echo "$BASE" > "$SANDBOX/.hm-registry-base"
for f in README.txt release.sh deploy.sh; do
  sed "s#@@BASE@@#$BASE#g" "$SANDBOX/$f" > "$HM_TMP/$f"
  cp "$HM_TMP/$f" "$SANDBOX/$f"
done

# Last week's release 0.2.0 was published the right way and is running.
helm package "$LEVEL_DIR/assets/payments-gateway" -d "$HM_TMP" >/dev/null
helm push "$HM_TMP/payments-gateway-0.2.0.tgz" "oci://$HM_REGISTRY/$BASE/charts" --plain-http >/dev/null
helm install payments-gateway "oci://$HM_REGISTRY/$BASE/charts/payments-gateway" --version 0.2.0 --plain-http \
  -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status payments-gateway deployed

# Today's release job pushes 0.3.0 ...
(cd "$SANDBOX" && bash ./release.sh >/dev/null 2>&1)
# ... and the rollout cannot find it.
if (cd "$SANDBOX" && bash ./deploy.sh >"$HM_TMP/deploy.txt" 2>&1); then
  echo "setup: deploy.sh succeeded — scenario is not broken"; exit 1
fi
grep -q "not found" "$HM_TMP/deploy.txt" || { cat "$HM_TMP/deploy.txt"; exit 1; }
