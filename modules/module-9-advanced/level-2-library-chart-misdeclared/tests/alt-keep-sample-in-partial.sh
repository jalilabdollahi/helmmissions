#!/bin/bash
# Valid alternative: keep the demo ConfigMap text, but in an underscore partial of a library chart; use uninstall+install.
set -euo pipefail
source "$HM_LIB"

mv mqlib/templates/mq-config.yaml mqlib/templates/_mq-config.tpl
sed -i.bak 's/^version: 0.1.0/type: library\nversion: 0.1.0/' mqlib/Chart.yaml && rm mqlib/Chart.yaml.bak
helm dependency update ./invoice-mailer >/dev/null
helm dependency update ./receipt-mailer >/dev/null
helm upgrade invoice-mailer ./invoice-mailer -n "$NS" --wait --timeout 120s
helm uninstall receipt-mailer -n "$NS" 2>/dev/null || true
helm install receipt-mailer ./receipt-mailer -n "$NS" --wait --timeout 120s
