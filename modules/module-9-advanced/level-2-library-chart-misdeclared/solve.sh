#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
rm -f mqlib/templates/mq-config.yaml
helm dependency update ./invoice-mailer
helm dependency update ./receipt-mailer
helm upgrade invoice-mailer ./invoice-mailer -n "$NS" --wait --timeout 120s
helm install receipt-mailer ./receipt-mailer -n "$NS" --wait --timeout 120s
