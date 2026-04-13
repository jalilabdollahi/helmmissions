#!/bin/bash
set -euo pipefail

RELEASE="helmissions-app"
NS="helmissions"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BROKEN="${HELMMISSIONS_SANDBOX:-$ROOT/broken}"
SOLUTION="${HELMMISSIONS_SOLUTION:-$ROOT/solution}"

echo "🔍 Comparing fixed chart to reference solution..."
if ! diff -ru --exclude='Chart.lock' "$SOLUTION" "$BROKEN" >/tmp/helmissions-diff.txt 2>&1; then
  echo "❌ The chart in broken/ still differs from the expected fixed chart in solution/."
  exit 1
fi

echo "🔍 Linting chart..."
if ! helm lint "$BROKEN" >/tmp/helmissions-lint.txt 2>&1; then
  echo "❌ helm lint failed"
  cat /tmp/helmissions-lint.txt
  exit 1
fi
helm dependency build "$BROKEN" >/tmp/helmissions-deps.txt 2>&1 || true

echo "🔍 Installing or upgrading release..."
if ! helm upgrade --install "$RELEASE" "$BROKEN" -n "$NS" --create-namespace >/tmp/helmissions-upgrade.txt 2>&1; then
  echo "❌ helm upgrade --install failed"
  cat /tmp/helmissions-upgrade.txt
  exit 1
fi

echo "🔍 Verifying live release status..."
STATUS="$(helm status "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.info.status // empty')"
if [[ "$STATUS" != "deployed" ]]; then
  echo "❌ Release not in deployed state (got: $STATUS)"
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
