#!/bin/bash
set -euo pipefail
source "$HM_LIB"

C="$LEVEL_DIR/assets/freight-quote"
up() { helm upgrade freight-quote "$C" -n "$NS" --reset-values "$@" >/dev/null; }
# rev 1: original service, insurance not built yet
helm install freight-quote "$C" -n "$NS" --set insurance=false --wait --timeout 90s >/dev/null
# rev 2: insurance shipped, but with an image tag typo
up --set insurance=true --set image.tag=1.27-alpin3
# rev 3: image fixed, but a bad nginx tuning value crashes the container
up --set insurance=true --set gzip=maybe
# rev 4: healthy, insurance on (the newest good one)
up --set insurance=true
# rev 5: readiness probe moved to a path that doesn't exist
up --set insurance=true --set readyPath=/ready
# rev 6: probe fixed, but the rate table was zeroed by a typo
helm upgrade freight-quote "$C" -n "$NS" --reset-values --set insurance=true --set rate=0 --wait --timeout 120s >/dev/null

hm_assert_status freight-quote deployed
[ "$(hm_release_revision freight-quote)" = "6" ] || { echo "setup: expected revision 6"; exit 1; }
hm_http_check http://freight-quote/quote >"$HM_TMP/q.txt" || { echo "setup: service not answering"; exit 1; }
grep -q '"rate":0' "$HM_TMP/q.txt" || { echo "setup: rate is not 0"; cat "$HM_TMP/q.txt"; exit 1; }
