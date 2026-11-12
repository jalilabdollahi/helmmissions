#!/bin/bash
# Valid alternative: also pin the kube version, and pass the API with the --flag=value spelling.
set -euo pipefail
source "$HM_LIB"

sed 's#--namespace helmissions -f env/prod.yaml#--namespace helmissions -f env/prod.yaml --kube-version 1.30.0 --api-versions=monitoring.helmissions.io/v1#' render.sh > "$HM_TMP/render.sh"
cp "$HM_TMP/render.sh" render.sh
chmod +x render.sh
./render.sh
kubectl apply -n "$NS" -f rendered/prod.yaml
