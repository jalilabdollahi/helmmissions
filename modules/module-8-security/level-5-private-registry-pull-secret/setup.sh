#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Level-managed private registry: auth required, one image pushed.
docker rm -f helmissions-private >/dev/null 2>&1 || true
docker create --name helmissions-private --network kind -p 127.0.0.1:5002:5000 \
  -e REGISTRY_AUTH=htpasswd -e REGISTRY_AUTH_HTPASSWD_REALM=helmissions \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/htpasswd registry:2 >/dev/null
docker cp "$LEVEL_DIR/assets/htpasswd" helmissions-private:/htpasswd
docker start helmissions-private >/dev/null
for _ in $(seq 1 30); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:5002/v2/ 2>/dev/null)" = 401 ] && break
  sleep 1
done
[ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:5002/v2/)" = 401 ] || { echo "setup: private registry did not come up with auth"; exit 1; }

export DOCKER_CONFIG="$HM_TMP/docker"; mkdir -p "$DOCKER_CONFIG"
echo 'Ship-It-2026' | docker login localhost:5002 -u depot --password-stdin >/dev/null
docker tag nginx:1.27-alpine localhost:5002/m8-portal/portal:1.0
docker push localhost:5002/m8-portal/portal:1.0 >/dev/null 2>&1
[ "$(curl -s -o /dev/null -w '%{http_code}' -u 'depot:Ship-It-2026' http://localhost:5002/v2/m8-portal/portal/tags/list)" = 200 ] || { echo "setup: image push failed"; exit 1; }

helm upgrade --install portal "$SANDBOX/partner-portal" -n "$NS" >/dev/null
hm_assert_status portal deployed
for _ in $(seq 1 40); do
  reason="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=portal -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || true)"
  case "$reason" in ErrImagePull|ImagePullBackOff) exit 0;; esac
  sleep 2
done
echo "setup: pods did not reach an image pull error (got '${reason:-none}')"; exit 1
