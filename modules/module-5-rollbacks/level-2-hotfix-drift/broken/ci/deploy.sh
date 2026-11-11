#!/bin/bash
# Production deploy step of the order-sync pipeline.
set -euo pipefail
cd "$(dirname "$0")/.."
helm upgrade --install order-sync ./order-sync -n helmissions -f values-prod.yaml --wait --timeout 90s
