#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed tsdb
[ "$(hm_release_chart tsdb)" = "timeseries-db-1.1.0" ] || hm_fail "Release tsdb runs chart '$(hm_release_chart tsdb)', expected timeseries-db-1.1.0"

hm_info "Checking the StatefulSet..."
vct="$(hm_jsonpath statefulset/tsdb '{.spec.volumeClaimTemplates[0].spec.resources.requests.storage}')"
[ "$vct" = "1Gi" ] || hm_fail "The StatefulSet's volumeClaimTemplate requests '$vct' - it must stay as it was in revision 1"
ret="$(hm_jsonpath statefulset/tsdb '{.spec.template.spec.containers[0].env[?(@.name=="RETENTION")].value}')"
[ "$ret" = "14d" ] || hm_fail "RETENTION is '$ret' - the retention change from chart 1.1.0 is not live"
mret="$(hm_manifest_json tsdb | jq -r '[.[]|select(.kind=="StatefulSet")][0].spec.template.spec.containers[0].env[]|select(.name=="RETENTION").value')"
[ "$mret" = "14d" ] || hm_fail "The release manifest says RETENTION=$mret"
hm_wait_rollout statefulset/tsdb "$NS" 120s

hm_info "Checking the data..."
kubectl exec statefulset/tsdb -n "$NS" -- cat /data/marker >"$HM_TMP/marker.txt" 2>&1 || hm_fail "Cannot read /data/marker in the tsdb pod"
grep -q "six months of telemetry" "$HM_TMP/marker.txt" || hm_fail "The telemetry data is gone - the volume was recreated" "$HM_TMP/marker.txt"
kubectl exec statefulset/tsdb -n "$NS" -- cat /data/config | grep -q "retention=14d" || hm_fail "The running pod does not use retention 14d"

hm_pass "tsdb runs chart 1.1.0 on its original volume with the data intact."
