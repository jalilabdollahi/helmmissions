#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed backup-scheduler
hm_manifest_json backup-scheduler | jq -e 'any(.[]; .kind=="BackupSchedule" and .metadata.name=="nightly")' >/dev/null \
  || hm_fail "The BackupSchedule 'nightly' is not part of the release"

hm_info "Checking the CRD and the custom resource..."
kubectl get crd backupschedules.helmissions.io >/dev/null 2>&1 || hm_fail "CRD backupschedules.helmissions.io does not exist"
[ "$(kubectl get crd backupschedules.helmissions.io -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)" = "True" ] \
  || hm_fail "CRD backupschedules.helmissions.io is not Established"
cron="$(hm_jsonpath backupschedule/nightly '{.spec.cron}')"
[ -n "$cron" ] || hm_fail "BackupSchedule nightly does not exist in the cluster"

hm_info "Checking the controller..."
hm_wait_rollout deployment/backup-scheduler-controller "$NS" 90s

hm_pass "CRD first, custom resource second — backup-scheduler is live."
