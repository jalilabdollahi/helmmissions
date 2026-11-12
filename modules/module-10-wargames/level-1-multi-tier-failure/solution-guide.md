# Solution guide - Three Tiers Down

1. Survey everything: `helm list --failed --deployed -n helmissions` and `kubectl get pods,jobs,svc -n helmissions`.
   `ledger-db` is `failed`, there is no db pod and no `ledger-db` Service, `ledger-api` pods sit in `Init:0/1`,
   and `ledger-web` runs but its page says `upstream ledger-api:80 failed`.
2. Database first. `helm status ledger-db -n helmissions` shows the hook failure. `kubectl logs job/ledger-db-migrate -n helmissions`
   prints `FATAL: unknown migration target 'v4' - this release ships v1 v2 v3`.
3. Edit `ledger-db/values.yaml`: `migrations.target: v3`. Then `helm upgrade --install ledger-db ./ledger-db -n helmissions --wait`
   (or `helm uninstall` + `helm install`). The hook runs again and now succeeds; the db Service appears.
4. API: `kubectl logs deploy/ledger-api -c wait-for-db -n helmissions` says it waits for `ledger-db-primary`. The Service is called
   `ledger-db`. Set `db.host: ledger-db` in `ledger-api/values.yaml`, `helm upgrade ledger-api ./ledger-api -n helmissions --wait`.
5. Front end: `kubectl get svc ledger-api` shows port 8080, the values say `ledger-api:80`. Set `api.upstream: ledger-api:8080`
   in `ledger-web/values.yaml` and upgrade `ledger-web`.
6. Verify: `kubectl run -it --rm probe --image=curlimages/curl:8.10.1 --restart=Never -n helmissions -- curl -s http://ledger-web/cgi-bin/balance`
   -> `web ok -> api ok -> db pong schema=v3`. `bash deploy.sh` must now finish cleanly.
