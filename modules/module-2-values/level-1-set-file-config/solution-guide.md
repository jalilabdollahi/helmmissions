# A Path Is Not A File - Walkthrough

1. The release is `deployed` but the pod is unhappy:
   ```bash
   kubectl get pods -n helmissions
   kubectl logs deploy/landing -n helmissions
   # nginx: [emerg] unknown directive "./site.conf" in /etc/nginx/conf.d/default.conf:1
   ```
2. Look at what Helm rendered:
   ```bash
   helm get manifest landing -n helmissions | grep -A3 'default.conf'
   helm get values landing -n helmissions
   # siteConfig: ./site.conf
   ```
   The ConfigMap contains the path as text. `--set` never reads files.
3. Feed the file contents to the chart with `--set-file`:
   ```bash
   helm upgrade landing ./landing -n helmissions --set-file siteConfig=./site.conf
   ```
   (Alternative: a values file with `siteConfig: |` followed by the indented server block, used with `-f`.)
4. Verify:
   ```bash
   kubectl get pods -n helmissions
   kubectl get cm landing-nginx -n helmissions -o jsonpath='{.data.default\.conf}'
   ```
5. Run `check`.
