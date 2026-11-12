# Orders platform - split into two namespaces

The platform team moved the orders back end out of the shared namespace during the cluster tenancy project.

| tier | release | namespace |
|------|---------|-----------|
| front end (customer dashboard) | `orders-web` | `helmissions-web` |
| back end (orders API) | `orders-api` | `helmissions-api` |

Dashboard check, from inside the front end's namespace: `http://orders-web/cgi-bin/dashboard`.
It should show the open order count that the back end serves, together with the namespace the back end runs in.

Deploy with `bash deploy.sh`. The front end worked before the move.
