#!/bin/bash
# HelmMissions cluster + local registry bootstrap.
#
#   scripts/cluster.sh create [cluster-name]   create kind cluster wired to the local registries
#   scripts/cluster.sh registry                 (re)start the shared local registries + chart repo
#   scripts/cluster.sh delete [cluster-name]
#
# Shared infrastructure (docker containers on the "kind" network):
#   helmissions-registry  OCI registry, no auth   host: localhost:5001  nodes: localhost:5001
#   helmissions-charts    nginx serving .hm-shared/chartrepo   host: http://localhost:8879
#   (port 5002 is reserved for a level-managed private registry named helmissions-private)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CMD="${1:-create}"
CLUSTER="${2:-helmissions}"
REG_NAME="helmissions-registry"
REG_PORT="5001"
PRIV_NAME="helmissions-private"
PRIV_PORT="5002"
CHARTS_NAME="helmissions-charts"
CHARTS_PORT="8879"
SHARED_DIR="$ROOT/.hm-shared"

ensure_network() {
  docker network inspect kind >/dev/null 2>&1 || docker network create kind >/dev/null
}

start_registry() {
  ensure_network
  if [ "$(docker inspect -f '{{.State.Running}}' "$REG_NAME" 2>/dev/null || true)" != "true" ]; then
    docker rm -f "$REG_NAME" >/dev/null 2>&1 || true
    docker run -d --restart=always -p "127.0.0.1:${REG_PORT}:5000" --network kind --name "$REG_NAME" registry:2 >/dev/null
  fi
  mkdir -p "$SHARED_DIR/chartrepo"
  if [ "$(docker inspect -f '{{.State.Running}}' "$CHARTS_NAME" 2>/dev/null || true)" != "true" ]; then
    docker rm -f "$CHARTS_NAME" >/dev/null 2>&1 || true
    docker run -d --restart=always -p "127.0.0.1:${CHARTS_PORT}:80" --network kind --name "$CHARTS_NAME" \
      -v "$SHARED_DIR/chartrepo:/usr/share/nginx/html:ro" nginx:1.27-alpine >/dev/null
  fi
  echo "✅ Local registry localhost:${REG_PORT} and chart repo http://localhost:${CHARTS_PORT} are running"
}

configure_nodes() {
  for node in $(kind get nodes --name "$CLUSTER"); do
    for pair in "${REG_PORT}:${REG_NAME}" "${PRIV_PORT}:${PRIV_NAME}"; do
      port="${pair%%:*}"; name="${pair#*:}"
      dir="/etc/containerd/certs.d/localhost:${port}"
      docker exec "$node" mkdir -p "$dir"
      printf '[host."http://%s:5000"]\n' "$name" | docker exec -i "$node" cp /dev/stdin "$dir/hosts.toml"
    done
  done
}

preload_images() {
  local images=(nginx:1.27-alpine nginxinc/nginx-unprivileged:1.27-alpine busybox:1.36 curlimages/curl:8.10.1 traefik/whoami:v1.10)
  for img in "${images[@]}"; do
    docker image inspect "$img" >/dev/null 2>&1 || docker pull -q "$img" >/dev/null
    kind load docker-image "$img" --name "$CLUSTER" >/dev/null 2>&1 || true
  done
  echo "✅ Common images preloaded into $CLUSTER"
}

case "$CMD" in
  create)
    start_registry
    if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
      echo "✅ Cluster '$CLUSTER' already exists"
    else
      cat <<EOF | kind create cluster --name "$CLUSTER" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF
    fi
    configure_nodes
    preload_images
    ;;
  registry)
    start_registry
    ;;
  delete)
    kind delete cluster --name "$CLUSTER"
    ;;
  *)
    echo "usage: $0 create|registry|delete [cluster-name]" >&2
    exit 1
    ;;
esac
