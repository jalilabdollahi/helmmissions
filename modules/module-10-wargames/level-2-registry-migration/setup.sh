#!/bin/bash
set -euo pipefail
source "$HM_LIB"
hm_registry_up

# The new registry already holds the copied images.
P="$HM_REGISTRY/m10-registry-migration"
for pair in cart:2.4 search:3.1 indexer:1.8 media:1.0; do
  docker tag traefik/whoami:v1.10 "$P/${pair%%:*}:${pair##*:}"
  docker push "$P/${pair%%:*}:${pair##*:}" >/dev/null
done

# The pipeline run after the cut-over, with the old registry still configured.
cd "$SANDBOX"
for rel in shop-cart shop-search shop-media; do
  helm upgrade --install "$rel" "./$rel" -n "$NS" -f values/global.yaml -f "values/$rel.yaml" >/dev/null
done

for _ in $(seq 1 45); do
  n="$(kubectl get pods -n "$NS" --no-headers 2>/dev/null | grep -cE 'ErrImagePull|ImagePullBackOff' || true)"
  [ "$n" -ge 4 ] && break
  sleep 2
done
[ "$n" -ge 4 ] || { echo "setup: expected 4 pods with pull errors, got $n"; kubectl get pods -n "$NS"; exit 1; }
for r in shop-cart shop-search shop-media; do hm_assert_status "$r" deployed; done
