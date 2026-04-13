#!/bin/bash
set -euo pipefail

NS="helmissions"
RELEASE="helmissions-app"
ROOT="$(cd "$(dirname "$0")" && pwd)"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
helm uninstall "$RELEASE" -n "$NS" >/dev/null 2>&1 || true
kubectl delete all --all -n "$NS" >/dev/null 2>&1 || true

helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
helm uninstall "$RELEASE" -n "$NS" --keep-history >/tmp/helmissions-uninstall.log 2>&1 || true
