#!/bin/bash
# CI job "deploy-notifier": roll out the new chart while keeping the settings of the running release
set -euo pipefail
helm upgrade notifier ./notifier -n helmissions --reuse-values --set image.tag=1.36 --wait --timeout 120s
