#!/bin/bash
# Alternative: stop relying on .Files and put the server block straight into the ConfigMap template.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cat > "$SANDBOX/legacy-site/templates/configmap.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-nginx
data:
  default.conf: |
    server {
        listen 8080;
        server_name _;
        location /healthz {
            default_type text/plain;
            return 200 "ok\n";
        }
        location / {
            default_type text/plain;
            return 200 "legacy-site: welcome\n";
        }
    }
EOF
printf '*.conf\n' >> "$SANDBOX/legacy-site/.helmignore"
helm upgrade site ./legacy-site -n "$NS" --wait --timeout 120s
