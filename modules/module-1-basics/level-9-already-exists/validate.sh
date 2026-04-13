#!/bin/bash
set -euo pipefail

RELEASE="helmissions-app"
NS="helmissions"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BROKEN="${HELMMISSIONS_SANDBOX:-$ROOT/broken}"
SOLUTION="${HELMMISSIONS_SOLUTION:-$ROOT/solution}"

TARGET_RELEASE="webapp"
echo "🔍 Checking idempotent upgrade flow..."
STATUS="$(helm status "$TARGET_RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.info.status // empty')"
if [[ "$STATUS" != "deployed" ]]; then
  echo "❌ Expected release $TARGET_RELEASE to remain deployed"
  exit 1
fi
COUNT="$(helm list -n "$NS" -o json 2>/dev/null | jq '[.[] | select(.name == "'"$TARGET_RELEASE"'")] | length')"
if [[ "${COUNT:-0}" != "1" ]]; then
  echo "❌ Expected exactly one $TARGET_RELEASE release in $NS"
  exit 1
fi
HISTORY_COUNT="$(helm history "$TARGET_RELEASE" -n "$NS" -o json 2>/dev/null | jq 'length')"
if [[ "${HISTORY_COUNT:-0}" -lt 2 ]]; then
  echo "❌ Expected an upgrade history entry for $TARGET_RELEASE"
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
