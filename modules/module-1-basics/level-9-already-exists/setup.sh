#!/bin/bash
set -euo pipefail

NS="helmissions"
RELEASE="helmissions-app"
ROOT="$(cd "$(dirname "$0")" && pwd)"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
helm uninstall "$RELEASE" -n "$NS" >/dev/null 2>&1 || true
kubectl delete all --all -n "$NS" >/dev/null 2>&1 || true

helm uninstall webapp -n "$NS" >/dev/null 2>&1 || true
helm install webapp "$ROOT/broken" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
