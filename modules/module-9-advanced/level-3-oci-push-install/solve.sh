#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/release.sh" release.sh
sed "s#@@BASE@@#$(cat .hm-registry-base)#g" release.sh > "$HM_TMP/release.sh"
cp "$HM_TMP/release.sh" release.sh
bash ./release.sh
bash ./deploy.sh
