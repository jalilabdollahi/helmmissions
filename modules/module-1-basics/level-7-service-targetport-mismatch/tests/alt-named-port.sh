#!/bin/bash
# Also valid: target the container's named port.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/targetPort: 8080/targetPort: http/' "$SANDBOX/inventory/values.yaml" && rm -f "$SANDBOX/inventory/values.yaml.bak"
helm upgrade inventory ./inventory -n "$NS" --wait --timeout 120s
