#!/bin/bash
# Production deploy step of the ticket-booking pipeline (no --wait: the idle colour may be mid-rollout).
set -euo pipefail
cd "$(dirname "$0")/.."
helm upgrade --install ticket-booking ./ticket-booking -n helmissions -f values-prod.yaml
