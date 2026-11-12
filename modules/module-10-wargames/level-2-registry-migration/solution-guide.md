# Solution guide - Registry Moved

1. `kubectl get pods -n helmissions` - four pods in `ErrImagePull`/`ImagePullBackOff` (cart, search, indexer, media).
   `kubectl describe pod ...` shows `registry.old.internal:5000/shop/...` cannot be resolved.
2. `values/global.yaml` sets `global.imageRegistry: registry.old.internal:5000/shop`. Change it to
   `localhost:5001/m10-registry-migration` (the path in `MIGRATION.md`).
3. Run `bash deploy-all.sh`. cart and search recover, but `shop-search-indexer` still pulls
   `registry.old.internal:5000/shop/indexer:1.8` - `helm get manifest shop-search | grep image:` shows it. The vendored
   subchart `shop-search/charts/indexer` uses its own `image.repository` and never reads `global.imageRegistry`.
   Fix its template to use `{{ .Values.global.imageRegistry }}/{{ .Values.image.repository }}` and set `repository: indexer`
   (or override `indexer.image.repository` in `values/shop-search.yaml`).
4. `shop-media` now says `manifest unknown` / `not found`: the tag `v1.0` does not exist.
   `curl -s http://localhost:5001/v2/m10-registry-migration/media/tags/list` lists `1.0`. Fix `values/shop-media.yaml`.
5. `bash deploy-all.sh` again; verify all pods Ready and `curl http://shop-media/` from a probe pod.
