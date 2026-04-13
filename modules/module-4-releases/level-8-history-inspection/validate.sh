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

echo "🔍 Inspecting release state..."
STATUS="$(helm status "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.info.status // empty')"
if [[ "$STATUS" != "deployed" ]]; then
  echo "❌ Release is not deployed (got: $STATUS)"
  exit 1
fi
HISTORY_COUNT="$(helm history "$RELEASE" -n "$NS" -o json 2>/dev/null | jq 'length')"
if [[ "${HISTORY_COUNT:-0}" -lt 1 ]]; then
  echo "❌ No release history found"
  exit 1
fi

LATEST_DESC="$(helm history "$RELEASE" -n "$NS" -o json | jq -r '.[-1].description // ""')"
if [[ "$LATEST_DESC" != *"Rollback"* && "$LATEST_DESC" != *"upgrade"* && "$LATEST_DESC" != *"Upgrade"* ]]; then
  echo "❌ Expected a recovery action in helm history"
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
