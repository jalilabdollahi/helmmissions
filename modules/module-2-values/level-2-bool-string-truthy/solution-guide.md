# "false" Is True - Walkthrough

1. See the Ingress and who owns it:
   ```bash
   kubectl get ingress -n helmissions
   helm get manifest storefront -n helmissions | grep -B1 -A3 'kind: Ingress'
   ```
   It is part of the Helm release, so deleting it with kubectl is not a fix.
2. Read the template guard and the value:
   ```bash
   head -3 storefront/templates/ingress.yaml        # {{- if .Values.ingress.enabled }}
   helm get values storefront -n helmissions --all | grep -A1 ingress   # enabled: "false"
   ```
3. Remove the quotes in `storefront/values.yaml`:
   ```yaml
   ingress:
     enabled: false
   ```
4. Upgrade and verify:
   ```bash
   helm upgrade storefront ./storefront -n helmissions
   kubectl get ingress -n helmissions        # No resources found
   helm get manifest storefront -n helmissions | grep -c Ingress   # 0
   ```
5. Run `check`.
