#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The release was created years ago by a client-side pipeline (Helm 3 era / --server-side=false).
flag=""; [ "$(hm_helm_major)" -ge 4 ] && flag="--server-side=false"
helm install thumbnail-svc "$SANDBOX/thumbnail-svc" -n "$NS" --set buildId=b-217 $flag --wait --timeout 90s >/dev/null
# the evening peak: the autoscaler (simulated) scales the Deployment up
kubectl scale deployment/thumbnail-svc -n "$NS" --replicas=5 >/dev/null
( cd "$SANDBOX" && bash ci/deploy.sh >/dev/null )

hm_assert_status thumbnail-svc deployed
[ "$(hm_release_revision thumbnail-svc)" = "2" ] || { echo "setup: expected revision 2"; exit 1; }
r="$(hm_jsonpath deployment/thumbnail-svc '{.spec.replicas}')"
[ "$r" = "2" ] || { echo "setup: deploy did not reset the replicas (now $r)"; exit 1; }
# ...and the autoscaler scales up again after the deploy
kubectl scale deployment/thumbnail-svc -n "$NS" --replicas=5 >/dev/null
kubectl get hpa thumbnail-svc -n "$NS" >/dev/null
