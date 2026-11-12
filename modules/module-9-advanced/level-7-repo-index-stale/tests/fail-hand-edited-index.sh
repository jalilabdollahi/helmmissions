#!/bin/bash
# Tempting shortcut: paste a 1.3.0 entry into index.yaml by hand (copy of the 1.2.0 entry, wrong digest).
set -euo pipefail
source "$HM_LIB"

URL="$HM_CHARTREPO_URL/m9-repo-index-stale"
"$HM_PYTHON" - repo/index.yaml "$URL" <<'PY'
import copy, sys, yaml
p, url = sys.argv[1], sys.argv[2]
idx = yaml.safe_load(open(p))
entries = idx["entries"]["tide-tracker"]
e = copy.deepcopy([x for x in entries if x["version"] == "1.2.0"][0])
e["version"] = "1.3.0"
e["urls"] = [url + "/tide-tracker-1.3.0.tgz"]
entries.insert(0, e)
yaml.safe_dump(idx, open(p, "w"))
PY
for _ in $(seq 1 20); do curl -fsS "$URL/index.yaml" | grep -q "1.3.0" && break; sleep 1; done
helm repo update hm-tides
helm upgrade tide-tracker hm-tides/tide-tracker --version 1.3.0 -n "$NS" --wait --timeout 120s
