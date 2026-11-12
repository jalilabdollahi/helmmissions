#!/bin/bash
# Tempting shortcut: skip the plugin and run the script by hand.
set -euo pipefail
source "$HM_LIB"

HELM_PLUGIN_DIR="$PWD/hm-audit" bash hm-audit/scripts/install-rules.sh
HELM_PLUGIN_DIR="$PWD/hm-audit" HELM_NAMESPACE="$NS" hm-audit/scripts/audit.sh checkout
