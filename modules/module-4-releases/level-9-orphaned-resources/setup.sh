#!/bin/bash
set -euo pipefail

NS="helmissions"
RELEASE="helmissions-app"
ROOT="$(cd "$(dirname "$0")" && pwd)"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
helm uninstall "$RELEASE" -n "$NS" >/dev/null 2>&1 || true
kubectl delete all --all -n "$NS" >/dev/null 2>&1 || true

kubectl -n "$NS" create service clusterip helmissions-app-orphan --tcp=80:80 >/tmp/helmissions-svc.log 2>&1 || true
