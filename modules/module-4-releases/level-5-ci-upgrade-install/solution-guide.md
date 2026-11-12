# First Deploy Breaks CI — Walkthrough

1. Reproduce:
   ```bash
   bash ci/deploy.sh
   # Error: UPGRADE FAILED: "shipment-tracker" has no deployed releases
   helm list -n helmissions              # empty
   ```
2. `helm upgrade` only works on an existing release. In staging it has always been there, so nobody noticed.
3. Edit `ci/deploy.sh`: `helm upgrade --install shipment-tracker "$CHART_DIR" --namespace "$NAMESPACE" --wait --timeout 90s`.
   (An explicit `helm status ... || helm install` branch is also fine, but `--install` is the idiom.)
4. Run it twice to prove it is idempotent:
   ```bash
   bash ci/deploy.sh
   bash ci/deploy.sh
   helm history shipment-tracker -n helmissions      # rev 1 install, rev 2 upgrade
   ```
5. The check will also run the script against a new empty namespace. Run `check`.
