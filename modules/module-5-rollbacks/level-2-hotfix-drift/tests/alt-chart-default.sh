#!/bin/bash
# Valid alternative: raise the chart default instead of the prod values file.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/poolSize: 5/poolSize: 40/' order-sync/values.yaml
rm -f order-sync/values.yaml.bak
bash ci/deploy.sh
