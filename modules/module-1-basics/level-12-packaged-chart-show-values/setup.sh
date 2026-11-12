#!/bin/bash
set -euo pipefail
source "$HM_LIB"

[ -f "$SANDBOX/vendor/node-probe-0.4.2.tgz" ] || { echo "setup: vendor chart missing"; exit 1; }
# Nothing is installed yet; make sure the packaged chart is readable.
helm show chart "$SANDBOX/vendor/node-probe-0.4.2.tgz" >/dev/null
