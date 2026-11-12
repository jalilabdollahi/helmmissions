#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=portal
REG=localhost:5002
hm_info "Checking the private registry..."
code="$(curl -s -o /dev/null -w '%{http_code}' "http://$REG/v2/" 2>/dev/null || true)"
[ "$code" = 401 ] || hm_fail "The private registry at $REG is not enforcing authentication (HTTP $code) — it must stay private"
hm_ok "Registry still requires credentials"

hm_require_deployed "$REL"
echo "$(hm_user_values "$REL")" | grep -q 'Ship-It-2026' && hm_fail "The registry password is stored in the release values"
hm_manifest_json "$REL" | jq -e '[.[]|select(.kind=="Secret")]|length==0' >/dev/null \
  || hm_fail "The release renders a Secret itself — the registry credentials must not travel through the chart"

hm_info "Checking the pods..."
hm_wait_rollout "deployment/$REL" "$NS" 45s
pods="$(hm_pods_json app.kubernetes.io/instance=$REL)"
ready="$(echo "$pods" | jq '[.[]|select(.status.phase=="Running" and (.status.containerStatuses[0].ready==true))]|length')"
[ "$ready" -ge 2 ] || hm_fail "Only $ready/2 portal pods are Ready (image pull is failing)"
echo "$pods" | jq -e "all(.[].spec.containers[]; .image | startswith(\"$REG/\"))" >/dev/null \
  || hm_fail "The pods no longer pull their image from the private registry $REG"
hm_ok "2 pods are Ready with images from $REG"

hm_info "Checking the pull credentials..."
sname="$(echo "$pods" | jq -r '[.[]|.spec.imagePullSecrets[]?.name][0] // empty')"
[ -n "$sname" ] || hm_fail "The pods carry no imagePullSecrets"
sec="$(kubectl get secret "$sname" -n "$NS" -o json 2>/dev/null || true)"
[ -n "$sec" ] || hm_fail "imagePullSecret '$sname' does not exist"
[ "$(echo "$sec" | jq -r .type)" = kubernetes.io/dockerconfigjson ] || hm_fail "Secret '$sname' is not of type kubernetes.io/dockerconfigjson"
cfg="$(echo "$sec" | jq -r '.data[".dockerconfigjson"]' | base64 -d 2>/dev/null)"
user="$(echo "$cfg" | jq -r --arg r "$REG" '.auths[$r].username // empty')"
pass="$(echo "$cfg" | jq -r --arg r "$REG" '.auths[$r].password // empty')"
[ -n "$user" ] || hm_fail "Secret '$sname' has no credentials for the server $REG"
[ "$(curl -s -o /dev/null -w '%{http_code}' -u "$user:$pass" "http://$REG/v2/")" = 200 ] || hm_fail "The credentials in Secret '$sname' are rejected by $REG"
hm_ok "Secret '$sname' carries working credentials for $REG"

hm_pass "The portal pulls from the private registry with proper credentials."
