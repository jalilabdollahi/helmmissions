# Somebody Deleted The Service - Walkthrough

1. Confirm the symptom: pods are Ready, but there is no Service.
   ```bash
   kubectl get svc,pods -n helmissions
   helm status sms-gateway -n helmissions         # still "deployed"
   helm get manifest sms-gateway -n helmissions | grep -A12 'kind: Service'
   ```
2. Re-apply the release through Helm. The Service is part of the manifest, so Helm creates it again:
   ```bash
   helm upgrade sms-gateway ./sms-gateway -n helmissions --wait
   ```
   Because `--reuse-values` is not needed here (the chart defaults are what you want), and Helm 4 keeps the
   previous user values anyway, this is a safe no-op for everything except the missing Service.
   ```bash
   helm history sms-gateway -n helmissions     # revision 3
   ```
3. Verify ownership and traffic:
   ```bash
   kubectl get svc sms-gateway -n helmissions -o yaml | grep -E 'helm|managed-by'
   kubectl get endpointslices -n helmissions
   ```
4. Run `check`.
