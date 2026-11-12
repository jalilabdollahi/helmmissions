#!/bin/bash
# Release script for payments-gateway.
# Policy PCI-7: only charts signed by the release key may be installed in this namespace.
set -euo pipefail

mkdir -p dist
helm package payments-gateway -d dist
helm upgrade --install payments-gateway dist/payments-gateway-1.0.0.tgz -n helmissions \
  --verify --keyring keys/signer-pubring.gpg --wait --timeout 120s
