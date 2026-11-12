#!/bin/bash
# Tempting workaround: override the value on the command line for this one upgrade.
set -euo pipefail
source "$HM_LIB"

helm upgrade orders ./orders-api -n "$NS" --set database.host=orders-db --wait --timeout 120s
