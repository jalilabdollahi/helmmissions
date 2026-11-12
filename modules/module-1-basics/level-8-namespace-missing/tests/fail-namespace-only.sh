#!/bin/bash
# Creates the namespace but never installs the release.
set -euo pipefail
source "$HM_LIB"

kubectl create namespace helmissions-staging
