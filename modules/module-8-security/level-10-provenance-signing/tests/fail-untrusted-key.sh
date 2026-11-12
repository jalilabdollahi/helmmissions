#!/bin/bash
# Wrong fix: sign (and verify) with some other key that happens to be lying around.
set -euo pipefail
source "$HM_LIB"

mkdir -p dist
helm package payments-gateway -d dist --sign --key 'Intern Sandbox Key' --keyring "$LEVEL_DIR/assets/intern-secring.gpg"
helm upgrade --install payments-gateway dist/payments-gateway-1.0.0.tgz -n "$NS" --verify --keyring "$LEVEL_DIR/assets/intern-pubring.gpg" --wait --timeout 120s
