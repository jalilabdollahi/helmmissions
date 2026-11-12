Payments chart registry convention
  Registry (plain HTTP):  localhost:5001
  Chart reference:        oci://localhost:5001/@@BASE@@/charts/payments-gateway
  Consumers pull it with: helm upgrade payments-gateway <reference> --version <x.y.z> --plain-http

release.sh   packages and publishes the chart in ./payments-gateway
deploy.sh    rolls the published version out to the cluster
