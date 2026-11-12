#!/bin/bash
# Package and publish payments-gateway to the internal registry.
set -euo pipefail
cd "$(dirname "$0")"
REGISTRY=localhost:5001
BASE=@@BASE@@

rm -rf dist
helm package payments-gateway -d dist
helm push dist/payments-gateway-*.tgz "oci://$REGISTRY/$BASE/charts" --plain-http
