#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Two real revisions installed years ago with the then-current chart; then the cluster dropped the old API versions.
helm install edge-gateway "$LEVEL_DIR/assets/edge-gateway" -n "$NS" --wait --timeout 90s >/dev/null
helm upgrade edge-gateway "$LEVEL_DIR/assets/edge-gateway" -n "$NS" --wait --timeout 90s >/dev/null

# The records still describe the objects with the API versions of their day (what a pre-1.22/1.25 Helm would have stored).
"$HM_PYTHON" - "$NS" <<'PY'
import base64, gzip, json, subprocess, sys
ns = sys.argv[1]
for rev in (1, 2):
    name = f"sh.helm.release.v1.edge-gateway.v{rev}"
    sec = json.loads(subprocess.check_output(["kubectl", "get", "secret", name, "-n", ns, "-o", "json"]))
    rel = json.loads(gzip.decompress(base64.b64decode(base64.b64decode(sec["data"]["release"]))))
    m = rel["manifest"]
    m = m.replace("apiVersion: policy/v1\n", "apiVersion: policy/v1beta1\n").replace("apiVersion: autoscaling/v2\n", "apiVersion: autoscaling/v2beta1\n")
    assert "policy/v1beta1" in m and "autoscaling/v2beta1" in m
    rel["manifest"] = m
    blob = base64.b64encode(gzip.compress(json.dumps(rel, separators=(",", ":")).encode()))
    patch = json.dumps({"data": {"release": base64.b64encode(blob).decode()}})
    subprocess.check_call(["kubectl", "patch", "secret", name, "-n", ns, "--type=merge", "-p", patch], stdout=subprocess.DEVNULL)
PY

# (helm status itself fails now: it needs REST mappings for the stored objects too)
[ "$(helm history edge-gateway -n "$NS" -o json | jq -r '.[-1] | "\(.revision) \(.status)"')" = "2 deployed" ] || { echo "setup: expected revision 2 deployed"; exit 1; }
helm upgrade edge-gateway "$SANDBOX/edge-gateway" -n "$NS" >"$HM_TMP/up.txt" 2>&1 && { echo "setup: upgrade unexpectedly worked"; exit 1; }
grep -q "resource mapping not found" "$HM_TMP/up.txt" || { cat "$HM_TMP/up.txt"; exit 1; }
# the same release, upgraded with a chart that uses served APIs, fails on the stored record
helm upgrade edge-gateway "$LEVEL_DIR/solution/edge-gateway" -n "$NS" >"$HM_TMP/rb.txt" 2>&1 && { echo "setup: upgrade with a clean chart unexpectedly worked"; exit 1; }
grep -q "unable to build kubernetes objects from current release manifest" "$HM_TMP/rb.txt" || { cat "$HM_TMP/rb.txt"; exit 1; }
[ "$(helm history edge-gateway -n "$NS" -o json | jq -r '.[-1].status')" = "deployed" ] || { echo "setup: release state changed"; exit 1; }
