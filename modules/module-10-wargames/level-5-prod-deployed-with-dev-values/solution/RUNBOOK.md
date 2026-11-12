# invoice service - environments

| env  | release       | namespace         | values file        |
|------|---------------|-------------------|--------------------|
| dev  | `invoice-dev` | `helmissions-dev` | `values-dev.yaml`  |
| prod | `invoice`     | `helmissions`     | `values-prod.yaml` |

Deploy with `bash deploy.sh dev` or `bash deploy.sh prod`.

What prod must look like (see the config page: `http://invoice/config.txt` in `helmissions`):
live payments, log level `warn`, no debug endpoints, 2 replicas, database `invoice-db.helmissions`.

Dev is allowed to be noisy: debug logging, sandbox payments, debug endpoints, 1 replica, database `invoice-db.helmissions-dev`.

Yesterday's "prod deploy" went out from the pipeline. Finance now reports test invoices in the real ledger.
