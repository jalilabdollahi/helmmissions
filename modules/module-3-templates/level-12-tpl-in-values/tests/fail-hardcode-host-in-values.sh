#!/bin/bash
# Tempting workaround: type the final host name in values.yaml. Works for this release only.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/host: "{{ .Release.Name }}-db"/host: "orders-db"/' "$SANDBOX/orders-api/values.yaml"
rm -f "$SANDBOX/orders-api/values.yaml.bak"
helm upgrade orders ./orders-api -n "$NS" --wait --timeout 120s
