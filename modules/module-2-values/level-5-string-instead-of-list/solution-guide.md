# Range Over A String - Walkthrough

1. Reproduce: `helm template cors-gateway ./cors-gateway`
   -> `range can't iterate over https://shop.example`.
2. The template does `{{- range .Values.allowedOrigins }}`; values.yaml has a plain string.
3. Make it a list in `cors-gateway/values.yaml`:
   ```yaml
   allowedOrigins:
     - https://shop.example
   ```
4. Check: `helm template cors-gateway ./cors-gateway | grep -A3 origins.txt`
5. Install: `helm install cors-gateway ./cors-gateway -n helmissions`, then run `check`.
