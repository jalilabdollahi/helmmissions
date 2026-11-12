# Registry migration - cut-over notes

The company is retiring `registry.old.internal:5000` (switched off at 01:00).
All shop images were copied to the new registry. Same image names, one project path:

    localhost:5001/m10-registry-migration/<image>

Images copied: `cart`, `search`, `indexer`, `media` (check the registry catalog / tag list for the exact tags:
`curl -s http://localhost:5001/v2/m10-registry-migration/<image>/tags/list`).

Releases (all in namespace `helmissions`), deployed by `deploy-all.sh` with `values/global.yaml` + `values/<release>.yaml`:

* `shop-cart`
* `shop-search` (has the `indexer` subchart)
* `shop-media`

The pipeline ran after the cut-over and shop pods have been unhappy since.
