# Umbrella Down — Walkthrough

1. Render and read the error:
   ```bash
   helm template marketplace ./marketplace --debug 2>&1 | tail
   # marketplace/charts/pricing/templates/deployment.yaml:...: nil pointer evaluating interface {}.cpu
   ```
2. `pricing/templates/deployment.yaml` reads `.Values.resources.limits.cpu`, but `pricing/values.yaml` only defines
   `resources.requests`. Add the limits (or set `pricing.resources.limits` in the umbrella values):
   ```yaml
   resources:
     requests: {cpu: 10m, memory: 16Mi}
     limits: {cpu: 50m, memory: 64Mi}
   ```
3. Render again; now compare the images:
   ```bash
   helm template marketplace ./marketplace | grep -E '^# Source|image:'
   ```
   gateway, catalog, pricing and notifier start with `docker.io/`; **cart** shows a bare `traefik/whoami:v1.10`.
4. `cart/templates/_helpers.tpl` builds the image from `.Values.imageRegistry` (cart's own, empty by default) instead of
   `.Values.global.imageRegistry`. Make it use the global (and drop the unused `imageRegistry` value).
5. Prove the policy by switching the global:
   ```bash
   helm template marketplace ./marketplace --set global.imageRegistry=mirror.example.test | grep image:
   ```
6. Install and verify five ready deployments: `helm install marketplace ./marketplace -n helmissions --wait`.
