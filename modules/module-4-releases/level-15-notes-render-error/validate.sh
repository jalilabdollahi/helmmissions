#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed status-page
hm_wait_rollout deployment/status-page "$NS" 90s

hm_info "Checking the release notes..."
notes="$(helm get notes status-page -n "$NS" 2>/dev/null)"
[ -n "$notes" ] || hm_fail "The release has no notes — NOTES.txt was removed instead of fixed"
echo "$notes" | grep -Eq 'https?://[A-Za-z0-9._-]+' || hm_fail "The notes do not show a URL for the status page"
echo "$notes" | grep -q 'nil\|<no value>' && hm_fail "The notes still contain an empty value"

hm_pass "status-page is live and its notes tell people where to find it."
