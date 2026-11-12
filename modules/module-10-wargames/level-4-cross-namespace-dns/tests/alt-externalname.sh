#!/bin/bash
# Alternative: keep the short name working in the front end's namespace with an ExternalName Service.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
perl -pi -e 's/host: orders-api\..*/host: orders-api/' orders-web/values.yaml
kubectl create service externalname orders-api --external-name orders-api.helmissions-api.svc.cluster.local -n helmissions-web
bash deploy.sh
