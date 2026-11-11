#!/bin/bash
# Valid alternative: replace the alias with the repository URL (no helm repo add needed for `update`).
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's#"@hm-stable"#http://localhost:8879/m6-repo-not-added#' statuspage/Chart.yaml && rm -f statuspage/Chart.yaml.bak
helm dependency update ./statuspage
helm install statuspage ./statuspage -n "$NS" --wait --timeout 120s
