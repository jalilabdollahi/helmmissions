#!/bin/bash
# Wrong fix: raise replicaCount so the reset is less painful - every deploy still overrides the autoscaler.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/replicaCount: 2/replicaCount: 5/' thumbnail-svc/values.yaml
rm -f thumbnail-svc/values.yaml.bak
bash ci/deploy.sh
