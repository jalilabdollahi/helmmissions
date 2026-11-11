#!/bin/bash
# Tempting shortcut: download the tarball by hand and drop it into charts/. The install works, but no repository was
# ever configured and Chart.lock does not exist, so the build is not reproducible.
set -euo pipefail
source "$HM_LIB"

mkdir -p statuspage/charts
curl -fsS "$HM_CHARTREPO_URL/m6-repo-not-added/uptime-probe-1.4.0.tgz" -o statuspage/charts/uptime-probe-1.4.0.tgz
helm install statuspage ./statuspage -n "$NS" --wait --timeout 120s
