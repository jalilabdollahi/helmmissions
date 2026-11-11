# function "uppercase" not defined - Walkthrough

1. `helm install dispatch ./dispatch -n helmissions` fails with
   `parse error at (dispatch/templates/deployment.yaml:28): function "uppercase" not defined`.
2. Function names are resolved while the template is *parsed*, so an unknown name stops everything before the
   cluster is contacted. Helm offers Go's built-ins and the Sprig function library; Sprig's name for this is `upper`.
3. Edit line 28: `value: {{ .Values.environment | upper | quote }}`.
4. `helm template dispatch ./dispatch | grep -A1 APP_ENV` should print `PRODUCTION`; try
   `--set environment=staging` to see `STAGING`.
5. `helm install dispatch ./dispatch -n helmissions --wait`, then
   `kubectl logs -n helmissions deploy/dispatch-worker` prints `dispatcher up in PRODUCTION`.
