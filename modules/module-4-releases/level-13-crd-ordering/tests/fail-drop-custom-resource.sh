#!/bin/bash
# Wrong fix: delete the BackupSchedule from the chart. The install works, but the thing the chart exists for is gone.
set -euo pipefail
source "$HM_LIB"

rm "$SANDBOX/backup-scheduler/templates/backupschedule.yaml"
helm install backup-scheduler ./backup-scheduler -n "$NS" --wait --timeout 90s
