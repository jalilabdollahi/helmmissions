#!/bin/bash
# Install hook: create the local rules file from the shipped defaults.
set -euo pipefail
cp "$HELM_PLUGIN_DIR/rules.default" "$HELM_PLUGIN_DIR/rules.env"
