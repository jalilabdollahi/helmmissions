#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install storefront ./storefront -n "$NS" --take-ownership --wait --timeout 120s
