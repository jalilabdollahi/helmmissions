#!/bin/bash
set -euo pipefail

NS="helmissions"
RELEASE="helmissions-app"
ROOT="$(cd "$(dirname "$0")" && pwd)"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
helm uninstall "$RELEASE" -n "$NS" >/dev/null 2>&1 || true
kubectl delete all --all -n "$NS" >/dev/null 2>&1 || true

helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace --set replicaCount=3 >/tmp/helmissions-setup.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set replicaCount=1 >/tmp/helmissions-upgrade.log 2>&1 || true
