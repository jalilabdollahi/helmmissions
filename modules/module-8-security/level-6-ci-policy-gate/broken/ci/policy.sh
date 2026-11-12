#!/bin/bash
# CI policy gate. Runs on every merge request. Owned by the security team (CODEOWNERS) — do not edit.
#   usage: bash ci/policy.sh [chart-dir]
set -uo pipefail
CHART="${1:-./report-worker}"
PY="${HM_PYTHON:-python3}"

objs="$(helm template gate "$CHART" -n ci | "$PY" -c '
import json, sys, yaml
print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))')" || { echo "helm template failed"; exit 2; }

violations=0
report() { while IFS= read -r line; do [ -n "$line" ] && { echo "POLICY VIOLATION: $line"; violations=$((violations+1)); }; done; }

# Rule 1: images must be pinned to a non-floating tag
report < <(echo "$objs" | jq -r '.[] | select(.spec.template.spec.containers) | .metadata.name as $w
  | .spec.template.spec.containers[]
  | (.image | split("/") | last) as $ref
  | select(($ref | contains("@") | not) and (($ref | contains(":") | not) or ($ref | endswith(":latest"))))
  | "\($w)/\(.name): image \(.image) uses a floating tag (pin a version)"')

# Rule 2: every container declares cpu and memory limits
report < <(echo "$objs" | jq -r '.[] | select(.spec.template.spec.containers) | .metadata.name as $w
  | .spec.template.spec.containers[]
  | select((.resources.limits.cpu // "") == "" or (.resources.limits.memory // "") == "")
  | "\($w)/\(.name): resources.limits.cpu and resources.limits.memory are required"')

# Rule 3: every container has a readinessProbe and a livenessProbe
report < <(echo "$objs" | jq -r '.[] | select(.spec.template.spec.containers) | .metadata.name as $w
  | .spec.template.spec.containers[]
  | select(.readinessProbe == null or .livenessProbe == null)
  | "\($w)/\(.name): readinessProbe and livenessProbe are required"')

if [ "$violations" -gt 0 ]; then
  echo "policy gate FAILED: $violations violation(s)"
  exit 1
fi
echo "policy gate passed"
