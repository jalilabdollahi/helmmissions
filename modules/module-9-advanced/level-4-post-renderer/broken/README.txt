edge-gateway/                    vendored upstream chart — do not edit (Renovate overwrites it)
plugins/hm-cost-labeler/         post-renderer plugin: stdin = rendered manifests, stdout = patched manifests
  plugin.yaml                    Helm 4 plugin definition (type postrenderer/v1)
  kustomization.yaml             the label + sidecar patch applied by render.sh
  render.sh                      runs `kubectl kustomize`

Install:  helm plugin install ./plugins/hm-cost-labeler
Use:      helm upgrade edge-gateway ./edge-gateway -n helmissions --post-renderer hm-cost-labeler
          (Helm 3 equivalent: --post-renderer ./path/to/executable)
