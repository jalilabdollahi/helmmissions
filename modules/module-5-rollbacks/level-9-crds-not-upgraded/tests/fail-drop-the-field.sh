#!/bin/bash
# Wrong fix: remove the new field from the chart so the upgrade passes - the 2.0 feature is silently dropped.
set -euo pipefail
source "$HM_LIB"

sed -i.bak '/retentionDays/d' snapshot-scheduler/templates/policy.yaml
rm -f snapshot-scheduler/templates/policy.yaml.bak
helm upgrade snapshots ./snapshot-scheduler -n "$NS" --wait --timeout 90s
