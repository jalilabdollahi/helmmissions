#!/bin/bash
# Valid alternative: move the legacy file out of the chart, wipe the stale lock and charts/, then `build`.
set -euo pipefail
source "$HM_LIB"

mv payroll/requirements.yaml ./requirements.yaml.old
rm -rf payroll/charts payroll/Chart.lock
helm dependency build ./payroll
helm upgrade payroll ./payroll -n "$NS" --wait --timeout 120s
