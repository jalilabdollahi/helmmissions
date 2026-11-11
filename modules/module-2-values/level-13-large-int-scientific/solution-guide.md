# 1.048576e+06 - Walkthrough

1. Look at the rendered value:
   ```bash
   helm template upload-proxy ./upload-proxy | grep MAX_UPLOAD
   # MAX_UPLOAD_BYTES: "1.048576e+06"
   kubectl logs deploy/upload-proxy -n helmissions
   ```
2. `values.yaml` holds the integer 1048576, but Helm decodes YAML into JSON-style float64 numbers. Go's default
   formatting of a float64 this large is scientific notation.
3. Convert the value inside the template:
   ```yaml
   MAX_UPLOAD_BYTES: {{ .Values.maxUploadBytes | int64 | quote }}
   ```
4. Test default and override:
   ```bash
   helm template upload-proxy ./upload-proxy | grep MAX_UPLOAD
   echo 'maxUploadBytes: 5242880' > /tmp/o.yaml
   helm template upload-proxy ./upload-proxy -f /tmp/o.yaml | grep MAX_UPLOAD
   ```
5. `helm upgrade upload-proxy ./upload-proxy -n helmissions`, then run `check`.
