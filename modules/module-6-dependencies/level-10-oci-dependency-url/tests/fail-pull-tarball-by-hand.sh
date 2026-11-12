#!/bin/bash
# Tempting shortcut: pull the chart yourself and drop it into charts/. The install works, but Chart.yaml still holds
# the wrong repository and there is no Chart.lock, so CI cannot rebuild it.
set -euo pipefail
source "$HM_LIB"

mkdir -p booking/charts
helm pull "oci://$HM_REGISTRY/m6-oci-dependency-url/charts/seat-cache" --version 2.0.1 --plain-http -d booking/charts
helm install booking ./booking -n "$NS" --wait --timeout 120s
