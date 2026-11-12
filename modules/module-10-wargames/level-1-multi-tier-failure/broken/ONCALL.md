# Ledger stack - on-call notes

Three Helm releases make up the ledger service, deployed by `deploy.sh` in this order:

    ledger-db  ->  ledger-api  ->  ledger-web

* `ledger-db`  - the database tier (runs a schema migration job before it starts)
* `ledger-api` - business logic, talks to the database
* `ledger-web` - the public front end, calls the API

Health page for the whole stack (run from inside the cluster):

    http://ledger-web/cgi-bin/balance

A healthy stack answers: `web ok -> api ok -> db pong schema=v3`

Last night's deploy was run by the pipeline and nobody looked at the result.
