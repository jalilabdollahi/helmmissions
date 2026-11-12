#!/bin/bash
set -euo pipefail
source "$HM_LIB"

C="$SANDBOX/checkout"
# rev 1: healthy
helm install checkout "$C" -n "$NS" --wait --timeout 90s >/dev/null
# rev 2: the vendor migration switches the provider to a gateway that has been retired
helm upgrade checkout "$C" -n "$NS" --reuse-values --set payment.provider=legacy-gw --wait --timeout 90s >/dev/null
# on-call forces the fallback breaker by hand during the outage
kubectl set env deployment/checkout FORCE_FALLBACK=1 -n "$NS" >/dev/null
kubectl rollout status deployment/checkout -n "$NS" --timeout=90s >/dev/null
# rev 3: the tuning PR (values-prod.yaml) with a timeout that is far too short
helm upgrade checkout "$C" -n "$NS" --reset-values -f "$SANDBOX/values-prod.yaml" --wait --timeout 90s >/dev/null

hm_assert_status checkout deployed
[ "$(hm_release_revision checkout)" = "3" ] || { echo "setup: expected revision 3"; exit 1; }
env="$(kubectl get deployment checkout -n "$NS" -o json | jq -r '.spec.template.spec.containers[0].env[]|select(.name=="FORCE_FALLBACK").value')"
[ "$env" = "1" ] || { echo "setup: the manual hotfix env is not present"; exit 1; }
for _ in $(seq 1 30); do
  [ "$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=checkout --no-headers | wc -l | tr -d ' ')" = "2" ] && break
  sleep 2
done
hm_http_check http://checkout/checkout.txt >"$HM_TMP/c.txt" || { echo "setup: service not answering"; exit 1; }
grep -q "FAILING" "$HM_TMP/c.txt" || { echo "setup: checkout is not failing"; cat "$HM_TMP/c.txt"; exit 1; }
