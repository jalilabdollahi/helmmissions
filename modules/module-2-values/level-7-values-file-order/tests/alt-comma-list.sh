#!/bin/bash
# Valid alternative: comma-separated files in one -f flag, in the right order.
set -euo pipefail
source "$HM_LIB"

cat > deploy.sh <<'SH'
#!/bin/bash
set -euo pipefail
helm upgrade --install checkout ./checkout -n helmissions-prod --create-namespace \
  -f values-base.yaml,values-prod.yaml --wait --timeout 120s
SH
bash ./deploy.sh
