# billing - promotion pipeline

`bash pipeline.sh` promotes the build in `VERSION` through three environments, in order:

| stage   | release           | namespace            | values file          |
|---------|-------------------|----------------------|----------------------|
| dev     | `billing-dev`     | `helmissions-dev`    | `values/dev.yaml`    |
| staging | `billing-staging` | `helmissions-staging`| `values/staging.yaml`|
| prod    | `billing`         | `helmissions`        | `values/prod.yaml`   |

Prod receives exactly the build that staging ran (the pipeline reads it back from the staging release).

Environment expectations (page `http://<release>/` inside each namespace shows them):
* dev:     `environment=dev`, 1 replica, sandbox payments, database `billing-db.helmissions-dev`
* staging: `environment=staging`, 1 replica, sandbox payments, database `billing-db.helmissions-staging`
* prod:    `environment=prod`, 2 replicas, live payments, database `billing-db.helmissions`

Last night's run printed errors, but the job was green. This morning prod billing is serving errors after the rollout.
