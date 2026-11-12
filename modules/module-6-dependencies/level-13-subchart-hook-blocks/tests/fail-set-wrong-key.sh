#!/bin/bash
# Wrong fix: the host is already set at the parent's `database.host`; passing it again at the top level changes nothing
# for the subchart, so the hook still fails.
set -euo pipefail
source "$HM_LIB"

helm upgrade checkout ./checkout -n "$NS" --set database.host=orders-db.helmissions.svc.cluster.local --wait --timeout 120s || true
