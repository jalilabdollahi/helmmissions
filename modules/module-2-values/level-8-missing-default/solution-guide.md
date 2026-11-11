# The Empty Timeout - Walkthrough

1. See the symptom:
   ```bash
   kubectl logs deploy/fetcher -n helmissions
   # fetcher: invalid FETCH_TIMEOUT='' (want seconds)
   helm get manifest fetcher -n helmissions | grep FETCH_TIMEOUT
   # FETCH_TIMEOUT=
   ```
2. `fetcher/values.yaml` only defines `http.retries`. `{{ .Values.http.timeout }}` of a missing key renders as
   an empty string - no error.
3. Give the template a fallback in `fetcher/templates/configmap.yaml`:
   ```yaml
   FETCH_TIMEOUT={{ .Values.http.timeout | default 30 }}
   ```
   (Adding `timeout: 30` to values.yaml also helps for this release, but then a values file that
   replaces the `http` block or sets `http.timeout: null` brings the empty value back.)
4. Check: `helm template fetcher ./fetcher | grep FETCH_` and `... --set http.timeout=45 | grep FETCH_`.
5. `helm upgrade fetcher ./fetcher -n helmissions`, confirm the pod is Ready, run `check`.
