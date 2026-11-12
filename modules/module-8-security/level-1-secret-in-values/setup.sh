#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The release as the team ships it today: password in values.yaml -> inline env value.
helm upgrade --install ledger-api "$SANDBOX/ledger-api" -n "$NS" -f "$SANDBOX/ledger-api/values.yaml" --wait --timeout 120s >/dev/null
hm_assert_status ledger-api deployed
val="$(kubectl get deploy ledger-api -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_PASSWORD")].value}')"
[ "$val" = "Tr0ub4dor&3-ledger-prod" ] || { echo "setup: plaintext password not live"; exit 1; }
