# Hook Job Already Exists — Walkthrough

1. Read the failure and the leftovers:
   ```bash
   helm history tax-engine -n helmissions            # rev 2 failed
   kubectl get jobs -n helmissions                   # tax-engine-rate-check  Complete  (from rev 1)
   helm get hooks tax-engine -n helmissions          # delete policy: hook-failed
   ```
2. The Job is a hook, so Helm does not own it as a normal resource. The policy `hook-failed` deletes it only after a failure, and
   rev 1 succeeded, so the Job stays. Rev 2 renders a Job with the same name but a different spec (it embeds the release
   revision), and Kubernetes refuses to change a Job's pod template (`field is immutable`; on older Helm:
   `jobs.batch ... already exists`).
3. Fix the chart: in `tax-engine/templates/rate-check-job.yaml` set
   ```yaml
   "helm.sh/hook-delete-policy": before-hook-creation,hook-failed
   ```
   (`before-hook-creation` removes the previous Job right before a new one is created; `hook-succeeded,hook-failed`
   would also work if you do not need to keep the logs).
4. Upgrade (no manual deletion needed):
   ```bash
   helm upgrade tax-engine ./tax-engine -n helmissions --wait
   helm upgrade tax-engine ./tax-engine -n helmissions --wait     # and again: still fine
   ```
5. Run `check`.
