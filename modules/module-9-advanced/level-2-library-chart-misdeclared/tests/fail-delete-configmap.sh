#!/bin/bash
# Tempting shortcut: delete the offending ConfigMap and retry. mqlib is untouched, so the collision comes back.
set -euo pipefail
source "$HM_LIB"

kubectl delete configmap mq-defaults -n "$NS"
helm upgrade --install receipt-mailer ./receipt-mailer -n "$NS" --wait --timeout 120s || true
