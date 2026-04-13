#!/bin/bash
set -euo pipefail

RELEASE="helmissions-app"
NS="helmissions"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BROKEN="${HELMMISSIONS_SANDBOX:-$ROOT/broken}"
SOLUTION="${HELMMISSIONS_SOLUTION:-$ROOT/solution}"

echo "🔍 Checking that the replica override used the correct values key..."
REPLICAS="$(kubectl get deploy -n "$NS" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].spec.replicas}' 2>/dev/null || echo 0)"
if [[ "$REPLICAS" != "5" ]]; then
  echo "❌ Expected replicaCount override to set 5 replicas"
  exit 1
fi
VALUES_REPLICAS="$(helm get values "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.replicaCount // empty')"
if [[ "$VALUES_REPLICAS" != "5" ]]; then
  echo "❌ helm get values does not show replicaCount=5"
  exit 1
fi

DEPLOY="$(kubectl get deploy -n "${TARGET_NS:-$NS}" -l app.kubernetes.io/instance="${TARGET_RELEASE:-$RELEASE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -n "$DEPLOY" ]]; then
  kubectl rollout status "deployment/$DEPLOY" -n "${TARGET_NS:-$NS}" --timeout=60s >/tmp/helmissions-rollout.txt 2>&1 || {
    echo "❌ Deployment did not become ready"
    cat /tmp/helmissions-rollout.txt
    exit 1
  }
fi

echo "✅ Level complete! Validation matched the behavior this mission is teaching."
