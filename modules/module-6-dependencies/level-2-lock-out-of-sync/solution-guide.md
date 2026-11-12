# Chart.lock Out Of Sync — Walkthrough

1. Reproduce the CI failure:
   ```bash
   cd sandbox/current
   helm dependency build ./ledger
   # Error: the lock file (Chart.lock) is out of sync with the dependencies file (Chart.yaml). ...
   ```
2. See the mismatch:
   ```bash
   helm dependency list ./ledger     # ledger-db 0.4.0 ... STATUS out-of-sync/wrong version
   cat ledger/Chart.lock             # version: 0.3.0
   ls ledger/charts                  # ledger-db-0.3.0.tgz
   ```
3. Re-resolve the dependency (this rewrites Chart.lock and replaces the tarball):
   ```bash
   helm dependency update ./ledger
   cat ledger/Chart.lock             # version: 0.4.0
   helm dependency build ./ledger    # now succeeds
   ```
4. Roll the new chart out and verify the subchart version that actually runs:
   ```bash
   helm upgrade ledger ./ledger -n helmissions --wait
   kubectl get deploy ledger-ledger-db -n helmissions -L helm.sh/chart
   ```
5. Run `check`.
