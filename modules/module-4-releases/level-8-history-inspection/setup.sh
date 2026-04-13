#!/bin/bash
set -euo pipefail

NS="helmissions"
RELEASE="helmissions-app"
ROOT="$(cd "$(dirname "$0")" && pwd)"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
helm uninstall "$RELEASE" -n "$NS" >/dev/null 2>&1 || true
kubectl delete all --all -n "$NS" >/dev/null 2>&1 || true

helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-2 >/tmp/helmissions-rev2.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/broken" -n "$NS" >/tmp/helmissions-rev3.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-4 >/tmp/helmissions-rev4.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-5 >/tmp/helmissions-rev5.log 2>&1 || true
