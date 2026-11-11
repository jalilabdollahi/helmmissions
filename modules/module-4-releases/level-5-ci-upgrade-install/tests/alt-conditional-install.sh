#!/bin/bash
# Valid alternative: explicit branch — install when the release is missing, upgrade otherwise.
set -euo pipefail
source "$HM_LIB"

cat > ci/deploy.sh <<'SH'
#!/bin/bash
set -euo pipefail
NAMESPACE="${NAMESPACE:-helmissions}"
CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)/shipment-tracker"
if helm status shipment-tracker -n "$NAMESPACE" >/dev/null 2>&1; then verb=upgrade; else verb=install; fi
helm "$verb" shipment-tracker "$CHART_DIR" -n "$NAMESPACE" --wait --timeout 90s
SH
bash ci/deploy.sh
