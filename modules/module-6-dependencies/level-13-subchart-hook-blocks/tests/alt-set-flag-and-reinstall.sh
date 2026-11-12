#!/bin/bash
# Valid alternative: uninstall the failed release and install again with the value scoped to the subchart.
set -euo pipefail
source "$HM_LIB"

helm uninstall checkout -n "$NS" >/dev/null
helm install checkout ./checkout -n "$NS" \
  --set schema-migrator.database.host=orders-db.helmissions.svc.cluster.local --wait --timeout 120s
