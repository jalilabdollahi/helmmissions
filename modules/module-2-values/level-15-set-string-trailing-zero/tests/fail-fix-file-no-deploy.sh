#!/bin/bash
# Tempting: fix the values file and forget to run the deploy.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^appVersionLabel: 1.10/appVersionLabel: "1.10"/' status-page/values.yaml
