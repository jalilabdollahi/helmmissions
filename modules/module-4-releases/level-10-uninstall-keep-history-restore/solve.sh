#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The last live configuration is revision 2 (an uninstall marks the last revision; it does not add one).
helm rollback loyalty-points 2 -n "$NS" --wait --timeout 120s
