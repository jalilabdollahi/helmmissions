#!/bin/bash
set -euo pipefail
source "$HM_LIB"
sha256_stdin() { "$HM_PYTHON" -c 'import sys,hashlib; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())'; }

helm install ledgerdb "$SANDBOX/ledger-db" -n "$NS" --wait --timeout 120s >/dev/null
p1="$(kubectl get secret ledgerdb-credentials -n "$NS" -o jsonpath='{.data.password}')"
# a routine upgrade: only the replica count changes, yet the password is regenerated
helm upgrade ledgerdb "$SANDBOX/ledger-db" -n "$NS" --reuse-values --set replicaCount=1 --wait --timeout 120s >/dev/null
p2="$(kubectl get secret ledgerdb-credentials -n "$NS" -o jsonpath='{.data.password}')"
[ "$p1" != "$p2" ] || { echo "setup: the password did not change on upgrade"; exit 1; }
[ "$(hm_release_revision ledgerdb)" = "2" ] || { echo "setup: expected revision 2"; exit 1; }
# the password currently registered with the billing system (fingerprint only)
fp="$(printf '%s' "$p2" | base64 -d | sha256_stdin)"
kubectl create configmap registered-credentials -n "$NS" --from-literal=fingerprint="$fp" --from-literal=system=billing >/dev/null
