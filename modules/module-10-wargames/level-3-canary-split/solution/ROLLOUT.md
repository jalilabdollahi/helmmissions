# catalog 2.0 canary rollout

Plan agreed in the release meeting:

* `catalog-stable` runs the current version and owns the shared Service `catalog`
* `catalog-canary` runs 2.0 and must receive roughly 10% of the traffic: 9 stable pods + 1 canary pod behind
  the same Service (the Service load-balances across all ready pods it selects)
* both are the same chart, deployed with `bash release.sh`

Observed since the rollout: the dashboard shows canary errors, traffic looks like a coin flip between versions,
and the on-call was told "canary is at 50%". The canary release itself is not green either.

Check from inside the cluster: `curl http://catalog/` answers `catalog <track> (<release>)`.
