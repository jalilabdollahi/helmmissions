#!/bin/bash
# Render the checkout chart for prod. CI runs this on a runner that has NO access to the cluster;
# the pipeline then applies rendered/prod.yaml.
set -euo pipefail
cd "$(dirname "$0")"

OUT="${OUT:-rendered/prod.yaml}"
mkdir -p "$(dirname "$OUT")"
helm template checkout ./checkout --namespace helmissions -f env/prod.yaml \
  --api-versions monitoring.helmissions.io/v1 > "$OUT"
echo "rendered $OUT"
