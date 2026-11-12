# Immutable Job Template - Walkthrough

1. Reproduce:
   ```bash
   helm upgrade catalog ./catalog-seed -n helmissions
   # Error: UPGRADE FAILED: server-side apply failed ... Job.batch "catalog-seed" is invalid:
   #        spec.template: Invalid value: ... field is immutable
   helm history catalog -n helmissions        # 2  failed
   ```
2. Understand: Job `catalog-seed` finished long ago with `SEED_VERSION=1`; chart 1.1.0 renders the same Job name
   with `SEED_VERSION=2`. `spec.template` of a Job is immutable.
   `--force-replace` does not help (Helm 4 refuses it together with server-side apply; with client-side apply
   the replace of a Job still fails because of the immutable selector).
3. Fix, option A - make each seed version its own Job. In `templates/seed-job.yaml`:
   ```yaml
   name: {{ .Release.Name }}-seed-v{{ .Values.seed.version }}
   ```
   Option B - delete the old Job: `kubectl delete job catalog-seed -n helmissions`.
4. Upgrade and verify:
   ```bash
   helm upgrade catalog ./catalog-seed -n helmissions --wait
   kubectl get jobs -n helmissions
   kubectl logs job/catalog-seed-v2 -n helmissions     # seeding catalog with dataset v2
   ```
