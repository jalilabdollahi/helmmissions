#!/bin/bash
# Wrong fix: run an equivalent pod by hand. It is not a hook of the release, so helm test still has nothing to run.
set -euo pipefail
source "$HM_LIB"

kubectl run search-test -n "$NS" --image=curlimages/curl:8.10.1 --image-pull-policy=IfNotPresent --restart=Never \
  --labels=app.kubernetes.io/component=test --command -- sh -c 'curl -fsS "http://search/search?q=boots"; echo hits'
sleep 5
