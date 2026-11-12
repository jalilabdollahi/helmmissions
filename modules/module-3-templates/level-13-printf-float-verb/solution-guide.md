# %!d(float64=8080) - Walkthrough

1. `kubectl get pods -n helmissions` shows CrashLoopBackOff; `kubectl logs deploy/ingest --previous` reports an
   invalid value for the `--port` flag. `kubectl get deploy ingest -o jsonpath='{.spec.template.spec.containers[0].args}'`
   shows `--port=%!d(float64=8080)`.
2. Find the source: `grep -rn printf ingest/templates` -> `printf "%d" .Values.port`.
3. Values read from a YAML file arrive in templates as float64 (JSON-style numbers). `%d` only accepts integers, so
   Go prints its error marker instead of failing the render.
4. Use `%v` (any value, prints 8080) or convert: `printf "%d" (int .Values.port)`.
5. Verify with the chart's values and with another file (`port: 9100`), then
   `helm upgrade ingest ./ingest -n helmissions --wait`.
