# INC-4471 - Tideline 2.0 release

Tideline is shipped as one umbrella chart (`tideline/`, with a `cache` dependency from the internal chart registry,
`oci://localhost:5001/m10-final-incident/charts`) and deployed by `bash deploy.sh staging|prod`.

| env     | release            | namespace             | values                                  |
|---------|--------------------|-----------------------|-----------------------------------------|
| staging | `tideline-staging` | `helmissions-staging` | `values/common.yaml` + `values/staging.yaml` |
| prod    | `tideline`         | `helmissions`         | `values/common.yaml` + `values/prod.yaml`    |

2.0 needs cache >= 1.2.0 and moves the database schema from 12 to 13 (the migration hook runs before every upgrade and refuses
to skip a schema version).

Status pages (inside each namespace): `http://tideline/cgi-bin/status` (prod), `http://tideline-staging/cgi-bin/status` (staging).
A healthy environment says `status=ok`, the cache version it runs, schema 13, and a database host that belongs to its own environment.

## Timeline
* 11:02  staging deployed with the 2.0 chart; QA reports "staging feels wrong" but nobody follows up
* 13:40  prod deploy of 2.0 started from CI; the runner was killed mid-run (out of memory) - the job is gone, nothing else was done
* 13:55  prod still serves traffic on the old revision; `helm upgrade` from every laptop is refused
* 14:10  release manager wants 2.0 out in both environments before the 15:00 freeze
