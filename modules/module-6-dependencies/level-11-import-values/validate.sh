#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/invoicing"

hm_info "Checking the API follows the database subchart's port..."
hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -e 'any(.[]; .name=="pg-lite")' >/dev/null \
  || hm_fail "invoicing/Chart.yaml no longer declares pg-lite"
db_port() { jq -r '[.[] | select(.kind=="Deployment" and (.metadata.name|test("-api$")))][0].spec.template.spec.containers[0].env // [] | map(select(.name=="DB_PORT") | .value) | first // ""'; }
svc_port() { jq -r '[.[] | select(.kind=="Service" and (.metadata.name|test("pg-lite$")))][0].spec.ports[0].port // ""'; }
r="$(hm_render_json "$CHART")"
[ -n "$r" ] && [ "$r" != "[]" ] || hm_fail "helm template ./invoicing fails" "$HM_TMP/render-err.txt"
[ "$(echo "$r" | db_port)" = "5432" ] || hm_fail "The API's DB_PORT is '$(echo "$r" | db_port)' while the database listens on $(echo "$r" | svc_port)"
# Prove it follows the subchart, not a copy: move the database in a scratch copy of the workspace and rebuild.
ws="$HM_TMP/follow"
mkdir -p "$ws"
cp -R "$SANDBOX/invoicing" "$ws/invoicing"
cp -R "$SANDBOX/pg-lite" "$ws/pg-lite"
"$HM_PYTHON" - "$ws/pg-lite/values.yaml" <<'PY'
import sys, yaml
p = sys.argv[1]
d = yaml.safe_load(open(p)) or {}
d.setdefault("service", {})["port"] = 6543
yaml.safe_dump(d, open(p, "w"))
PY
helm dependency update "$ws/invoicing" >"$HM_TMP/ws-dep.txt" 2>&1 || hm_fail "helm dependency update fails for the chart" "$HM_TMP/ws-dep.txt"
r2="$(hm_render_json "$ws/invoicing")"
[ "$(echo "$r2" | svc_port)" = "6543" ] || hm_fail "Internal check could not move the database port"
[ "$(echo "$r2" | db_port)" = "6543" ] || hm_fail "After the database moves to port 6543 the API still points at port $(echo "$r2" | db_port): the port is not coming from the subchart"
hm_ok "DB_PORT follows pg-lite's service port"

hm_info "Checking the release..."
hm_require_deployed invoicing
chart="$(hm_release_chart invoicing)"
[ "$chart" = "invoicing-1.8.0" ] || hm_fail "Release invoicing runs chart '$chart', expected invoicing-1.8.0"
[ "$(hm_manifest_json invoicing | db_port)" = "5432" ] || hm_fail "The released API Deployment has no DB_PORT=5432"
hm_wait_rollout deployment/invoicing-api "$NS" 90s
hm_wait_rollout deployment/invoicing-pg-lite "$NS" 90s
hm_pass "invoicing finds its database port through the subchart."
