# Patch After Render — Walkthrough

1. See the failing upgrade and look at the plugin:
   ```bash
   helm plugin list                       # hm-cost-labeler, TYPE postrenderer/v1
   helm template edge-gateway ./edge-gateway --post-renderer hm-cost-labeler
   # Error: error while running post render on files: ... exited with error
   ```
2. A post-renderer is just `stdin → stdout`. Run it by hand to see the real error:
   ```bash
   helm template edge-gateway ./edge-gateway > /tmp/rendered.yaml
   HELM_PLUGIN_DIR=$PWD/plugins/hm-cost-labeler ./plugins/hm-cost-labeler/render.sh < /tmp/rendered.yaml
   # error: accumulating resources: ... rendered.yaml ... no such file or directory
   ```
3. `render.sh` stores stdin in `all.yaml`, but `kustomization.yaml` lists `rendered.yaml` as its resource.
   Make them agree, e.g. change `resources:` to `all.yaml`.
4. Verify the output, then upgrade (plugins installed in development mode point at the workspace, so no reinstall is needed):
   ```bash
   helm template edge-gateway ./edge-gateway --post-renderer hm-cost-labeler | grep -E 'cost-center|log-shipper'
   helm upgrade edge-gateway ./edge-gateway -n helmissions --post-renderer hm-cost-labeler --wait
   ```
5. Verify `helm get manifest edge-gateway -n helmissions | grep -c cost-center` and `kubectl get pods -n helmissions`
   (2/2 containers ready). Helm 3 equivalent: make render.sh a plain executable and pass `--post-renderer ./render.sh`.
