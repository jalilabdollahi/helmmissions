# Solution guide - Silent Pipeline Failure

1. `helm list -A --failed --deployed`: `billing` (prod) is `failed`, `billing-dev` is fine, there is no `billing-staging` release.
2. `kubectl get pods -n helmissions` shows a pod in `InvalidImageName`; `kubectl describe pod` says the image is `busybox:` (empty tag).
   `helm get values billing -n helmissions` shows `image.tag: ""`.
3. `bash pipeline.sh` (or read it): the staging stage prints `Error: open values/staging.yaml: no such file or directory`; because the script
   has no `set -e`, it then reads the promoted tag from a staging release that does not exist, gets an empty string and promotes it to prod.
4. Create `values/staging.yaml` (`environment: staging`, `replicaCount: 1`, sandbox payments, database `billing-db.helmissions-staging`).
5. Add `set -euo pipefail` near the top of `pipeline.sh` (or `|| exit 1` after the helm call in `deploy`), so a failing stage ends the run.
6. Run `bash pipeline.sh`: dev, staging, then prod (upgrading the failed release to a new revision with the staged build `1.36`).
   Verify the three pages. To test fail-fast, make staging fail on purpose and check that the exit code is non-zero and prod's revision does not change.
