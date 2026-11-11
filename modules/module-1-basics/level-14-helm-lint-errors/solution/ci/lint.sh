#!/bin/bash
# CI gate for the newsletter chart: the pipeline stops here unless this passes.
set -euo pipefail
cd "$(dirname "$0")/.."
helm lint --strict ./newsletter
