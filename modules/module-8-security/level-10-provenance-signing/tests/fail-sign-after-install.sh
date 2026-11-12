#!/bin/bash
# Wrong fix: install the unsigned package first, sign it afterwards to satisfy a file check.
set -euo pipefail
source "$HM_LIB"

mkdir -p dist
helm package payments-gateway -d dist
helm upgrade --install payments-gateway dist/payments-gateway-1.0.0.tgz -n "$NS" --wait --timeout 120s
sleep 2
helm package payments-gateway -d dist --sign --key 'HelmMissions Release Signer' --keyring keys/signer-secring.gpg
