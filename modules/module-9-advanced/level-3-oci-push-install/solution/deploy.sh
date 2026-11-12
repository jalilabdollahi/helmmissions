#!/bin/bash
# Roll a published payments-gateway version out to the cluster.
set -euo pipefail
VERSION="${1:-0.3.0}"
helm upgrade payments-gateway "oci://localhost:5001/@@BASE@@/charts/payments-gateway" \
  --version "$VERSION" --plain-http -n helmissions --wait --timeout 120s
