#!/bin/bash
# Valid alternative: no script edit, run the steps by hand: sign, verify, install with --verify.
set -euo pipefail
source "$HM_LIB"

mkdir -p dist
helm package payments-gateway -d dist --sign --key 'HelmMissions Release Signer' --keyring keys/signer-secring.gpg
helm verify dist/payments-gateway-1.0.0.tgz --keyring keys/signer-pubring.gpg
helm install payments-gateway dist/payments-gateway-1.0.0.tgz -n "$NS" --verify --keyring keys/signer-pubring.gpg --wait --timeout 120s
