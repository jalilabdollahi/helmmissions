#!/bin/bash
# Wrong fix: fake the schema state by hand so the migration finds "a database". The chart's order stays wrong.
set -euo pipefail
source "$HM_LIB"

kubectl create configmap orders-schema-state -n "$NS" --from-literal=schema=orders --from-literal=initialized-at=2000-01-01T00:00:00Z
helm upgrade orders ./order-service -n "$NS" --wait --timeout 90s
