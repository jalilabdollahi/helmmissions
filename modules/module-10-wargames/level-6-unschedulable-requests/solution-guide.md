# Solution guide - Pending Forever

1. `helm list -n helmissions --failed`: all three are failed. `kubectl get pods -n helmissions`: three or four new pods are `Pending`,
   the three old ones (version 1.0) run on.
2. `kubectl describe pod <pending-ingest>`: `0/1 nodes are available: 1 Insufficient cpu`. The values say `cpu: "500"` - 500 whole cores.
   Use `250m`.
3. rollup: `Insufficient memory`; `memory: 2048Gi` should have been `Mi`-scale. Use e.g. `256Mi`.
4. alerts: `1 node(s) didn't match Pod's node selector` - nodeSelector `workload-class: telemetry` matches no node. Remove it.
   After that the second replica stays Pending with `didn't match pod anti-affinity rules`: `affinity.mode: required` needs two nodes.
   Use `preferred` (spread when possible, still schedule on a single node).
5. `bash release.sh`. Each release moves to a new revision, status `deployed`; `curl http://telemetry-ingest/` says `version=2.0`.
   Rolling back to revision 1 would have worked technically but ships nothing.
