#!/bin/bash
# Tempting shortcut: keep feeding the legacy file. It happens to work today, but the chart still has two competing
# dependency lists, and the legacy one silently wins over Chart.yaml.
set -euo pipefail
source "$HM_LIB"

cat >> payroll/requirements.yaml <<'YAML'
  - name: pay-calendar
    version: 1.0.0
    repository: file://../pay-calendar
YAML
helm dependency update ./payroll
helm upgrade payroll ./payroll -n "$NS" --wait --timeout 120s
