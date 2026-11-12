#!/bin/bash
# Deploy the status page (release train 1.10)
set -euo pipefail
helm upgrade --install status-page ./status-page -n helmissions -f status-page/values.yaml --wait --timeout 120s
