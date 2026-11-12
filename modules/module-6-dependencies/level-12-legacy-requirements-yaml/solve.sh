#!/bin/bash
set -euo pipefail
source "$HM_LIB"

rm -f payroll/requirements.yaml
helm dependency update ./payroll
helm upgrade payroll ./payroll -n "$NS" --wait --timeout 120s
