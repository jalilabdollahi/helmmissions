#!/bin/bash
set -euo pipefail
NS="${NS:-helmissions}"
cd "$(dirname "$0")"
helm upgrade --install catalog-stable ./catalog -n "$NS" -f values-stable.yaml --wait --timeout 60s
helm upgrade --install catalog-canary ./catalog -n "$NS" -f values-canary.yaml --wait --timeout 60s
