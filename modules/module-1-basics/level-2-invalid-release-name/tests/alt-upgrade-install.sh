#!/bin/bash
# Another valid fix: make the script idempotent with `upgrade --install` and a variable for the name.
set -euo pipefail
source "$HM_LIB"

cat >"$SANDBOX/deploy.sh" <<'SH'
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
RELEASE="shop-frontend"
helm upgrade --install "$RELEASE" ./storefront --namespace helmissions --wait --timeout 120s
SH
bash "$SANDBOX/deploy.sh"
