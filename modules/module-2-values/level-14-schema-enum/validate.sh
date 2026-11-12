#!/bin/bash
set -uo pipefail
source "$HM_LIB"

SCHEMA="$SANDBOX/search-api/values.schema.json"
SCHEMA_SHA="53926546f438f0bd518ce8e17209e7020e450423e54dd3d978bb9e43b1913068"

hm_info "Checking the schema is untouched..."
[ -f "$SCHEMA" ] || hm_fail "search-api/values.schema.json was removed - it is the platform team's policy file"
got="$(shasum -a 256 "$SCHEMA" 2>/dev/null | cut -d' ' -f1 || true)"
[ -n "$got" ] || got="$(sha256sum "$SCHEMA" | cut -d' ' -f1)"
[ "$got" = "$SCHEMA_SHA" ] || hm_fail "values.schema.json was modified - the schema is policy and must stay as delivered"
hm_ok "Schema unchanged"

hm_require_deployed search-api
vals="$(hm_all_values search-api)"
echo "$vals" | jq -e '.logLevel | IN("debug","info","warn","error")' >/dev/null || hm_fail "The release runs with logLevel '$(echo "$vals" | jq -r .logLevel)', which the schema does not allow (it was installed around the validation)"
echo "$vals" | jq -e '(.replicas | type == "number") and .replicas >= 1' >/dev/null || hm_fail "The release runs with replicas=$(echo "$vals" | jq -r .replicas), the schema requires at least 1"

hm_wait_rollout deployment/search-api "$NS" 90s
ready="$(hm_jsonpath deployment/search-api '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] || hm_fail "Deployment search-api has no ready pod"
hm_pass "search-api runs with schema-valid values."
