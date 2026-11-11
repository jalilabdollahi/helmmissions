#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the releases..."
hm_require_deployed storefront
[ -z "$(hm_release_status shop)" ] || hm_fail "Release shop exists again — the rename should leave only storefront"

hm_info "Checking the Secret..."
sec="$(kubectl get secret db-credentials -n "$NS" -o json 2>/dev/null)" || hm_fail "Secret db-credentials does not exist"
[ "$(echo "$sec" | jq -r '.metadata.annotations["meta.helm.sh/release-name"] // ""')" = "storefront" ] \
  || hm_fail "Secret db-credentials still belongs to release '$(echo "$sec" | jq -r '.metadata.annotations["meta.helm.sh/release-name"] // "none"')'"
hm_manifest_json storefront | jq -e 'any(.[]; .kind=="Secret" and .metadata.name=="db-credentials")' >/dev/null \
  || hm_fail "The release manifest of storefront does not contain the Secret"
[ -n "$(echo "$sec" | jq -r '.data.DB_PASSWORD // empty')" ] || hm_fail "Secret db-credentials has no DB_PASSWORD"

hm_info "Checking the workload..."
hm_wait_rollout deployment/storefront "$NS" 90s

hm_pass "storefront owns the credentials and is live."
