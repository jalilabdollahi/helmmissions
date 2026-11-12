#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# 1. The stored record of the current revision still names API versions the cluster no longer serves: patch it, like mapkubeapis does.
rev="$(helm history edge-gateway -n "$NS" -o json | jq -r '.[-1].revision')"
"$HM_PYTHON" - "$NS" "$rev" <<'PY'
import base64, gzip, json, subprocess, sys
ns, rev = sys.argv[1], sys.argv[2]
name = f"sh.helm.release.v1.edge-gateway.v{rev}"
sec = json.loads(subprocess.check_output(["kubectl", "get", "secret", name, "-n", ns, "-o", "json"]))
rel = json.loads(gzip.decompress(base64.b64decode(base64.b64decode(sec["data"]["release"]))))
rel["manifest"] = rel["manifest"].replace("apiVersion: policy/v1beta1\n", "apiVersion: policy/v1\n").replace("apiVersion: autoscaling/v2beta1\n", "apiVersion: autoscaling/v2\n")
blob = base64.b64encode(gzip.compress(json.dumps(rel, separators=(",", ":")).encode()))
patch = json.dumps({"data": {"release": base64.b64encode(blob).decode()}})
subprocess.check_call(["kubectl", "patch", "secret", name, "-n", ns, "--type=merge", "-p", patch])
PY
# 2. The chart itself must use served APIs and valid autoscaling bounds.
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
# 3. Now the upgrade can be built.
helm upgrade edge-gateway "$SANDBOX/edge-gateway" -n "$NS" --wait --timeout 90s
