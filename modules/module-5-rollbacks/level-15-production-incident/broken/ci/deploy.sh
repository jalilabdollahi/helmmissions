#!/bin/bash
# Production deploy step of the checkout pipeline.
set -euo pipefail
cd "$(dirname "$0")/.."
helm upgrade --install checkout ./checkout -n helmissions -f values-prod.yaml --wait --timeout 90s
