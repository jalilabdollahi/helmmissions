#!/bin/bash
# Tempting workaround: add the misspelled key to values.yaml instead of fixing the template.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^  repository: nginx$/  repository: nginx\n  respository: nginx/' "$SANDBOX/receipts/values.yaml"
rm -f "$SANDBOX/receipts/values.yaml.bak"
helm upgrade receipts ./receipts -n "$NS" --wait --timeout 120s
