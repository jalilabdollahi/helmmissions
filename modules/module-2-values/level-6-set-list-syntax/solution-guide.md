# Commas In --set - Walkthrough

1. Run the runbook command and read the error:
   ```bash
   bash install.sh
   # Error: failed parsing --set data: key "internal" has no value
   ```
2. `--set a=x,b=y` sets two keys; `payments.svc.cluster.local,corp.internal` is read as
   `dnsSearch=payments.svc.cluster.local` followed by a bare key `corp.internal`.
3. Use list syntax:
   ```bash
   helm install mesh-client ./mesh-client -n helmissions \
     --set 'dnsSearch={payments.svc.cluster.local,corp.internal}'
   ```
   or index syntax with two `--set` flags (`dnsSearch[0]=...`, `dnsSearch[1]=...`), or a values file.
4. Verify:
   ```bash
   kubectl get deploy mesh-client -n helmissions -o jsonpath='{.spec.template.spec.dnsConfig.searches}'
   kubectl exec deploy/mesh-client -n helmissions -- cat /etc/resolv.conf
   ```
5. Run `check`.
