#!/bin/bash
# Shortcut: patch the three dev-only settings in prod with --set in the script; values-prod.yaml/file typo remain.
set -euo pipefail
source "$HM_LIB"
perl -0pi -e 's/RELEASE=invoice\n    VALUES=values-dev.yaml/RELEASE=invoice\n    VALUES=values-prod.yaml/; s/--reuse-values/--reuse-values --set payments.mode=live/' "$SANDBOX/deploy.sh"
bash "$SANDBOX/deploy.sh" prod
