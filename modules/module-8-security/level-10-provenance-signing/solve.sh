#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/deploy.sh" "$SANDBOX/deploy.sh"
bash ./deploy.sh
helm verify dist/payments-gateway-1.0.0.tgz --keyring keys/signer-pubring.gpg
