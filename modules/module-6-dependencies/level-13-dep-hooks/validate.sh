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

echo "🔍 Validating dependency metadata..."
if [[ ! -f "$BROKEN/Chart.lock" ]]; then
  echo "❌ Chart.lock is missing"
  exit 1
fi
if ! helm dependency build "$BROKEN" >/tmp/helmissions-deps.txt 2>&1; then
  echo "❌ helm dependency build failed"
  cat /tmp/helmissions-deps.txt
  exit 1
fi

echo "🔍 Installing chart with dependencies..."
if ! helm upgrade --install "$RELEASE" "$BROKEN" -n "$NS" --create-namespace >/tmp/helmissions-upgrade.txt 2>&1; then
  echo "❌ helm upgrade --install failed after dependency resolution"
  cat /tmp/helmissions-upgrade.txt
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
