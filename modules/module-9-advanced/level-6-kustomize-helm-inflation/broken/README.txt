platform/                     GitOps folder for the storefront catalog (prod)
  kustomization.yaml          inflates the vendored chart with `helmCharts`, then adds env=prod
  charts/catalog-api/         vendored chart
  values/prod.yaml            prod values

Deploy (no Helm release is created; Helm only renders):
  kubectl kustomize --enable-helm platform | kubectl apply -f -
