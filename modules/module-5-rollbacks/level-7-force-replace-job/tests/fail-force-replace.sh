#!/bin/bash
# Tempting wrong fix: --force-replace. On Helm 4 it cannot be combined with server-side apply, and with
# client-side apply replacing a Job still fails on its immutable selector. The release stays failed.
set -euo pipefail
source "$HM_LIB"

helm upgrade catalog ./catalog-seed -n "$NS" "$(hm_flag_force_replace)" --timeout 60s || true
helm upgrade catalog ./catalog-seed -n "$NS" --server-side=false "$(hm_flag_force_replace)" --timeout 60s 2>/dev/null || true
