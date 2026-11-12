#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm dependency update "$SANDBOX/invoice-mailer" >/dev/null
helm dependency update "$SANDBOX/receipt-mailer" >/dev/null
helm install invoice-mailer "$SANDBOX/invoice-mailer" -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status invoice-mailer deployed
if helm install receipt-mailer "$SANDBOX/receipt-mailer" -n "$NS" --timeout 60s >"$HM_TMP/second.txt" 2>&1; then
  echo "setup: receipt-mailer installed — scenario is not broken"; exit 1
fi
grep -q 'ConfigMap "mq-defaults"' "$HM_TMP/second.txt" || { cat "$HM_TMP/second.txt"; exit 1; }
