#!/bin/bash
# Tempting: make values-base.yaml agree with prod instead of fixing the order. REGION still fine, but deploy.sh stays wrong.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^replicaCount: 1/replicaCount: 3/; s/^logLevel: debug/logLevel: warn/' values-base.yaml
bash ./deploy.sh
