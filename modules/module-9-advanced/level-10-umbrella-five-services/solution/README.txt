marketplace/                  umbrella chart (release name: marketplace)
  values.yaml                 umbrella defaults, incl. global.imageRegistry
  charts/gateway/             edge routing
  charts/catalog/             product catalog + config
  charts/cart/                shopping carts
  charts/pricing/             price calculation
  charts/notifier/            e-mail / push worker

Policy: every image is "<global.imageRegistry>/<repository>:<tag>" — one switch for all subcharts.
