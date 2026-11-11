#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade sms-gateway ./sms-gateway -n "$NS" --wait --timeout 90s
