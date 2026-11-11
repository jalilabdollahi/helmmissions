#!/bin/bash
# Production deploy step of the thumbnail-svc pipeline.
set -euo pipefail
cd "$(dirname "$0")/.."
helm upgrade --install thumbnail-svc ./thumbnail-svc -n helmissions -f values-prod.yaml
