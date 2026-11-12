#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Prove the trap: packaging the chart as shipped puts the junk into the archive.
mkdir -p "$HM_TMP/probe"
helm package "$SANDBOX/reports" -d "$HM_TMP/probe" >/dev/null
tar tzf "$HM_TMP/probe/reports-1.1.0.tgz" | grep -q 'secrets.local.env' || { echo "setup: junk not packaged"; exit 1; }
[ ! -e "$SANDBOX/reports/.helmignore" ] || { echo "setup: .helmignore already exists"; exit 1; }
