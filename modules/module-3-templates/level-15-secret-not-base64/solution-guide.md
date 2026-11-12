# illegal base64 data - Walkthrough

1. The install error ends with `error decoding from json: illegal base64 data at input byte 2` for the Secret
   `gateway-provider`.
2. `helm template gateway ./payments-gw -s templates/secret.yaml` shows `data:` with `api-key: "sk-test-9f41c7a2d8"`.
   `data` must hold base64 (the `-` in `sk-test` is not even a base64 character).
3. Fix in `templates/secret.yaml`: pipe through `b64enc` (`{{ .Values.provider.apiKey | b64enc | quote }}`) or use
   `stringData:` with the plain value.
4. Do not encode the key in values.yaml by hand - the chart contract is a plain key and the template does the encoding.
5. `helm upgrade --install gateway ./payments-gw -n helmissions --wait`, then
   `kubectl get secret gateway-provider -n helmissions -o jsonpath='{.data.api-key}' | base64 -d`.
