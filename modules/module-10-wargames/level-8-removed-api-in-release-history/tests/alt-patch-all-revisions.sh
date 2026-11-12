#!/bin/bash
# Alternative: patch every stored revision (so a rollback to any of them also works), then upgrade.
set -euo pipefail
source "$HM_LIB"
for rev in 1 2; do
"$HM_PYTHON" - "$NS" "$rev" <<'PY'
import base64, gzip, json, subprocess, sys
ns, rev = sys.argv[1], sys.argv[2]
name = f"sh.helm.release.v1.edge-gateway.v{rev}"
sec = json.loads(subprocess.check_output(["kubectl", "get", "secret", name, "-n", ns, "-o", "json"]))
rel = json.loads(gzip.decompress(base64.b64decode(base64.b64decode(sec["data"]["release"]))))
rel["manifest"] = rel["manifest"].replace("policy/v1beta1", "policy/v1").replace("autoscaling/v2beta1", "autoscaling/v2")
blob = base64.b64encode(gzip.compress(json.dumps(rel, separators=(",", ":")).encode()))
subprocess.check_call(["kubectl", "patch", "secret", name, "-n", ns, "--type=merge", "-p", json.dumps({"data": {"release": base64.b64encode(blob).decode()}})])
PY
done
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade edge-gateway "$SANDBOX/edge-gateway" -n "$NS" --wait --timeout 90s
helm rollback edge-gateway 1 -n "$NS" --wait --timeout 90s
helm upgrade edge-gateway "$SANDBOX/edge-gateway" -n "$NS" --wait --timeout 90s
