#!/bin/bash
# Valid alternative: leave plugin.yaml alone and move the scripts to the paths it names.
set -euo pipefail
source "$HM_LIB"

mkdir -p hm-audit/bin hm-audit/hooks
mv hm-audit/scripts/audit.sh hm-audit/bin/audit.sh
mv hm-audit/scripts/install-rules.sh hm-audit/hooks/install-rules.sh
helm plugin uninstall hm-audit
helm plugin install ./hm-audit
