#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Both services were installed from their own copy of the helpers.
helm install ledger-api "$SANDBOX/ledger-api" -n "$NS" --wait --timeout 120s >/dev/null
helm install ledger-worker "$SANDBOX/ledger-worker" -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status ledger-api deployed
hm_assert_status ledger-worker deployed
# The scenario: the labels really drifted.
a="$(kubectl get deploy ledger-api -n "$NS" -o json | jq -r '.metadata.labels["app.kubernetes.io/part-of"] // "none"')"
w="$(kubectl get deploy ledger-worker -n "$NS" -o json | jq -r '.metadata.labels["app.kubernetes.io/part-of"] // "none"')"
[ "$a" = none ] && [ "$w" = ledger-platform ] || { echo "setup: labels did not drift ($a / $w)"; exit 1; }
