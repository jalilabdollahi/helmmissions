# Solution guide - Dev Values In Prod

1. `curl http://invoice/config.txt` (probe pod) shows `environment=dev`, sandbox payments, debug on. `helm get values invoice -n helmissions`
   lists exactly the keys of `values-dev.yaml`.
2. Read `deploy.sh`: the `prod)` branch sets `VALUES=values-dev.yaml` (copy and paste). Change it to `values-prod.yaml`.
3. Re-running only that is not enough: `helm get values` still shows `debugEndpoints: true`, `payments.mode: sandbox`.
   The script calls `helm upgrade --reuse-values`, which merges the previous release's user values into the new ones, so keys
   missing from `values-prod.yaml` keep their dev settings. Use `--reset-values` (or remove the flag).
4. `values-prod.yaml` contains `loglevel: warn`; the chart reads `logLevel`. Helm ignores unknown keys silently, so prod logged at
   `info`. Fix the spelling.
5. `bash deploy.sh prod` twice; the config page now reads prod/live/warn/false; `invoice-dev` is unchanged.
