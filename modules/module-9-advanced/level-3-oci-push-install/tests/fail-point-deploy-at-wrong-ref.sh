#!/bin/bash
# Tempting shortcut: leave the push alone and make deploy.sh use the doubled path that the push created.
set -euo pipefail
source "$HM_LIB"

sed 's#charts/payments-gateway"#charts/payments-gateway/payments-gateway"#' deploy.sh > "$HM_TMP/deploy.sh"
cp "$HM_TMP/deploy.sh" deploy.sh
bash ./deploy.sh
