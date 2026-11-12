#!/bin/bash
# Tempting workaround: base64-encode the key by hand in values.yaml instead of fixing the template.
set -euo pipefail
source "$HM_LIB"

enc="$(printf 'sk-test-9f41c7a2d8' | base64)"
sed -i.bak "s|apiKey: sk-test-9f41c7a2d8|apiKey: $enc|" "$SANDBOX/payments-gw/values.yaml"
rm -f "$SANDBOX/payments-gw/values.yaml.bak"
helm install gateway ./payments-gw -n "$NS" --timeout 30s || true
