#!/bin/bash
# Production deploy step of the geo-lookup pipeline.
set -euo pipefail
cd "$(dirname "$0")/.."
helm upgrade --install geo-lookup ./geo-lookup -n helmissions -f values-prod.yaml --history-max 3 --wait --timeout 90s
