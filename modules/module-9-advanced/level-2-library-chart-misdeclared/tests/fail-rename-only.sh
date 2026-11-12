#!/bin/bash
# Partial fix: the helper file is renamed (stray ConfigMap disappears) but mqlib is still an application chart.
set -euo pipefail
source "$HM_LIB"

mv mqlib/templates/mq-config.yaml mqlib/templates/_mq-config.tpl
helm dependency update ./invoice-mailer >/dev/null
helm dependency update ./receipt-mailer >/dev/null
helm upgrade invoice-mailer ./invoice-mailer -n "$NS" --wait --timeout 120s
helm upgrade --install receipt-mailer ./receipt-mailer -n "$NS" --wait --timeout 120s
