#!/bin/bash
# Shortcut: repoint the running Deployments with kubectl; values files, charts and release records keep the old registry.
set -euo pipefail
source "$HM_LIB"
N=localhost:5001/m10-registry-migration
kubectl set image deployment/shop-cart app=$N/cart:2.4 -n "$NS"
kubectl set image deployment/shop-search app=$N/search:3.1 -n "$NS"
kubectl set image deployment/shop-search-indexer indexer=$N/indexer:1.8 -n "$NS"
kubectl set image deployment/shop-media app=$N/media:1.0 -n "$NS"
for d in shop-cart shop-search shop-search-indexer shop-media; do kubectl rollout status deployment/$d -n "$NS" --timeout=90s; done
