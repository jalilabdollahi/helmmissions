# no template named "shop.labels" - Walkthrough

1. `helm template shop ./storefront` fails: `error calling include: template: no template "shop.labels" associated with template "gotpl"` in `service.yaml`.
2. Named templates are global to the chart (plus its subcharts) and are looked up by exact string.
   `grep -rn 'define' storefront/templates` shows `storefront.selectorLabels` and `storefront.labels`; there is no `shop.labels`.
3. `grep -rn include storefront/templates` shows that only `service.yaml` still uses the old name.
4. Change it to `{{- include "storefront.labels" . | nindent 4 }}`.
5. Compare: `helm template shop ./storefront | grep -B1 -A6 'kind: Service'` - the labels now match the Deployment.
6. `helm install shop ./storefront -n helmissions --wait`.
