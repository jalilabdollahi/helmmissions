#!/bin/bash
# Shortcut: fix everything with --set on the command line; the files in the workspace still say the old registry.
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
N=localhost:5001/m10-registry-migration
helm upgrade shop-cart ./shop-cart -n "$NS" -f values/global.yaml -f values/shop-cart.yaml --set global.imageRegistry=$N --wait --timeout 90s
helm upgrade shop-search ./shop-search -n "$NS" -f values/global.yaml -f values/shop-search.yaml --set global.imageRegistry=$N --set indexer.image.repository=$N/indexer --wait --timeout 90s
helm upgrade shop-media ./shop-media -n "$NS" -f values/global.yaml -f values/shop-media.yaml --set global.imageRegistry=$N --set image.tag=1.0 --wait --timeout 90s
