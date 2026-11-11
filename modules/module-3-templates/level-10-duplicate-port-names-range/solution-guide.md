# Duplicate Port Names - Walkthrough

1. `helm install edge ./mesh-edge -n helmissions` is rejected by the API server:
   `Service "edge" is invalid: spec.ports[1].name: Duplicate value: "http"`.
2. `helm template edge ./mesh-edge -s templates/service.yaml` shows three ports that are all called `http`.
3. In `templates/service.yaml` the range body has a hard-coded `name: http`; only the port number comes from the list.
   The Deployment template of the same chart uses `{{ .name }}` and is fine.
4. Change it to `name: {{ .name }}`.
5. `helm upgrade --install edge ./mesh-edge -n helmissions --wait` (use upgrade --install or uninstall first if the
   failed attempt left a release record behind), then `kubectl get svc edge -n helmissions`.
