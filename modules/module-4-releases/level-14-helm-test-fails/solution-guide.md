# Red Test Suite — Walkthrough

1. See the failure and the reason:
   ```bash
   helm test rating-service -n helmissions --logs
   # curl: (6) Could not resolve host: rating-service-api
   kubectl get svc -n helmissions          # the Service is called rating-service, port 80
   ```
2. Fix `rating-service/templates/tests/test-connection.yaml`: the URL must be
   `http://{{ .Release.Name }}:{{ .Values.service.port }}/health`.
3. A test pod is a *hook* and hooks are stored in the release revision. Running `helm test` now would still run the old pod,
   so create a new revision first:
   ```bash
   helm upgrade rating-service ./rating-service -n helmissions --wait
   helm test rating-service -n helmissions --logs
   ```
4. Run `check`.
