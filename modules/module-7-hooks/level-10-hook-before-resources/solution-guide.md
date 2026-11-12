# The Secret Isn't There Yet — Walkthrough

1. See why the hook Job is stuck:
   ```bash
   kubectl get pods -n helmissions                       # payroll-db-bootstrap-xxxx  CreateContainerConfigError
   kubectl describe pod -l app.kubernetes.io/component=db-bootstrap -n helmissions | tail -5   # secret "payroll-db" not found
   kubectl get secret -n helmissions                     # no payroll-db
   ```
2. Order of events: render, run `pre-install` hooks (waiting for each), then create the regular resources. The Secret is a regular resource,
   so it comes into existence only after the bootstrap Job it blocks. The Job gives up at its `activeDeadlineSeconds` and the install fails.
3. Make the Secret a hook that runs earlier. In `payroll-api/templates/secret.yaml` add
   ```yaml
   annotations:
     "helm.sh/hook": pre-install,pre-upgrade
     "helm.sh/hook-weight": "-10"
     "helm.sh/hook-delete-policy": before-hook-creation
   ```
   (the Job has weight 0). Do not use `hook-succeeded`: the Deployment needs the Secret afterwards.
4. Reinstall the failed release:
   ```bash
   helm uninstall payroll -n helmissions
   helm install payroll ./payroll-api -n helmissions --wait
   kubectl logs job/payroll-db-bootstrap -n helmissions
   kubectl get secret payroll-db -n helmissions
   ```
5. Run `check`.
