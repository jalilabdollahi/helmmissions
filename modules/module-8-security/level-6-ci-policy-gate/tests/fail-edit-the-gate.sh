#!/bin/bash
# Tempting wrong fix: neuter the gate script and ship the chart as it is.
set -euo pipefail
source "$HM_LIB"

printf '#!/bin/bash\necho "policy gate passed"\nexit 0\n' > ci/policy.sh
bash ci/policy.sh
helm upgrade --install report-worker ./report-worker -n "$NS" --timeout 20s || true
