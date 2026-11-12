# Solution guide - The Final Incident

1. Survey: `helm list -A`, `helm history tideline -n helmissions` -> revision 2 is `pending-upgrade` (the killed run); `helm upgrade` says
   `another operation (install/upgrade/rollback) is in progress`. `kubectl get pods,jobs -n helmissions` shows the abandoned `tideline-migrate` hook job.
2. Inputs: `helm dependency list ./tideline` -> `cache ~1.2.0 ... wrong version` (charts/ holds 1.1.0, Chart.lock pins 1.1.0). Run
   `helm dependency update ./tideline --plain-http` (needs `--plain-http` for the local registry).
3. Unstick prod: `helm rollback tideline 1 -n helmissions --wait` (rev 3 = "Rollback to 1"), or delete the Secret of the pending revision. Do not `--force`/uninstall.
4. Values: read the hook log (`kubectl logs job/tideline-migrate -n helmissions` after a run): `refusing to skip migrations: schema is at 12, target is 14`.
   `values/prod.yaml` overrides `schema.target: 14`; remove it so prod uses 13 from `values/common.yaml`.
5. Staging page (`http://tideline-staging/cgi-bin/status`) says `status=degraded`, `database-belongs-to-another-environment`; `values/staging.yaml` has the prod host.
   Set `tideline-db.helmissions-staging`.
6. `bash deploy.sh staging`, then `bash deploy.sh prod`. Verify both status pages: `status=ok`, `cache=1.2.0`, `schema=13`, own database host.
   Check `helm history tideline`: the newest revision is `deployed` (the abandoned revision 2 stays listed as `pending-upgrade`, harmless once superseded).
