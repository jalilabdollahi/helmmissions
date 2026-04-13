#!/bin/bash
set -euo pipefail

RELEASE="helmissions-app"
NS="helmissions"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BROKEN="${HELMMISSIONS_SANDBOX:-$ROOT/broken}"
SOLUTION="${HELMMISSIONS_SOLUTION:-$ROOT/solution}"

TARGET_NS="helmissions-extra"
echo "🔍 Checking that the release was installed into the missing namespace..."
STATUS="$(helm status "$RELEASE" -n "$TARGET_NS" -o json 2>/dev/null | jq -r '.info.status // empty')"
if [[ "$STATUS" != "deployed" ]]; then
  echo "❌ Expected release $RELEASE to be deployed in $TARGET_NS"
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
