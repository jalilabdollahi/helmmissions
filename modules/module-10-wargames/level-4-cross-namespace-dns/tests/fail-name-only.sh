#!/bin/bash
# Partial fix: only the host name is corrected; the resolver policy and the Service port stay broken.
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
perl -pi -e 's/host: orders-api$/host: orders-api.helmissions-api.svc.cluster.local/' orders-web/values.yaml
helm upgrade orders-web ./orders-web -n helmissions-web --wait --timeout 60s
