#!/bin/bash
# Valid alternative: write the good values explicitly into values-prod.yaml.
set -euo pipefail
source "$HM_LIB"

cat > values-prod.yaml <<'EOF'
provider: maps-v2
ttl: 300
trace: false
EOF
bash ci/deploy.sh
