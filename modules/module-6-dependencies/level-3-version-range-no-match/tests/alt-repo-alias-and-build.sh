#!/bin/bash
# Valid alternative: add the repo under an hm-* name, reference it by @alias, pin an exact 1.2.3.
set -euo pipefail
source "$HM_LIB"

helm repo add hm-platform "$HM_CHARTREPO_URL/m6-version-range-no-match" >/dev/null
"$HM_PYTHON" - <<'PY'
p = "searchdesk/Chart.yaml"
s = open(p).read()
s = s.replace('"^2.0.0"', '"1.2.3"').replace("http://localhost:8879/m6-version-range-no-match", '"@hm-platform"')
open(p, "w").write(s)
PY
helm dependency update ./searchdesk
helm install searchdesk ./searchdesk -n "$NS" --wait --timeout 120s
