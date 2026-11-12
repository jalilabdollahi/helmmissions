# No Matches For Kind — Walkthrough

1. Reproduce: `helm install backup-scheduler ./backup-scheduler -n helmissions` fails with
   `no matches for kind "BackupSchedule" ... ensure CRDs are installed first`. `kubectl get crd | grep helmissions` is empty.
2. `ls -R backup-scheduler` shows `templates/crd.yaml` next to `templates/backupschedule.yaml`.
   Helm builds all objects of a release in one go, so the custom resource cannot be mapped.
3. Create `backup-scheduler/crds/` and move the CRD there (without Helm templating):
   ```bash
   mkdir backup-scheduler/crds
   mv backup-scheduler/templates/crd.yaml backup-scheduler/crds/backupschedule-crd.yaml
   ```
4. Install: `helm install backup-scheduler ./backup-scheduler -n helmissions --wait`.
5. Verify `kubectl get crd backupschedules.helmissions.io`, `kubectl get backupschedules -n helmissions` and
   `helm get manifest backup-scheduler -n helmissions` (the CRD is not in the manifest; Helm manages `crds/` differently). Run `check`.
