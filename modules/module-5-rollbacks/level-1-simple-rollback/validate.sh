#!/bin/bash
set -euo pipefail

RELEASE="helmissions-app"
NS="helmissions"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BROKEN="${HELMMISSIONS_SANDBOX:-$ROOT/broken}"
SOLUTION="${HELMMISSIONS_SOLUTION:-$ROOT/solution}"

echo "🔍 Linting chart..."
if ! helm lint "$BROKEN" >/tmp/helmissions-lint.txt 2>&1; then
  echo "❌ helm lint failed"
  cat /tmp/helmissions-lint.txt
  exit 1
fi
helm dependency build "$BROKEN" >/tmp/helmissions-deps.txt 2>&1 || true

echo "🔍 Checking rollback history..."
STATUS="$(helm status "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.info.status // empty')"
if [[ "$STATUS" != "deployed" ]]; then
  echo "❌ Release is not deployed after rollback/recovery"
  exit 1
fi
LATEST_DESC="$(helm history "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.[-1].description // ""')"
if [[ "$LATEST_DESC" != *"Rollback"* && "$LATEST_DESC" != *"rollback"* && "$LATEST_DESC" != *"Upgrade"* ]]; then
  echo "❌ Expected the latest history entry to show rollback or recovery activity"
  exit 1
fi

IMAGE="$(kubectl get deploy -n "$NS" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [[ "$IMAGE" == *"latestt"* ]]; then
  echo "❌ Rollback did not restore the good image"
  exit 1
fi

DEPLOY="$(kubectl get deploy -n "$NS" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -n "$DEPLOY" ]]; then
  kubectl rollout status "deployment/$DEPLOY" -n "$NS" --timeout=60s >/tmp/helmissions-rollout.txt 2>&1 || {
    echo "❌ Deployment did not become ready"
    cat /tmp/helmissions-rollout.txt
    exit 1
  }
fi

echo "✅ Level complete! Validation matched the behavior this mission is teaching."
