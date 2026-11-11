# Read The Label - Walkthrough

1. Inspect the packaged chart without unpacking it:
   ```bash
   helm show chart  vendor/node-probe-0.4.2.tgz
   helm show readme vendor/node-probe-0.4.2.tgz
   helm show values vendor/node-probe-0.4.2.tgz
   ```
   The values contain `telemetry.servicePort: 80` with the comment "Port the Service exposes to scrapers".
2. Write the override in a values file:
   ```yaml
   # probe-values.yaml
   telemetry:
     servicePort: 9100
   ```
3. Install the archive:
   ```bash
   helm install node-probe vendor/node-probe-0.4.2.tgz -n helmissions -f probe-values.yaml --wait
   ```
4. Verify:
   ```bash
   helm get values node-probe -n helmissions
   kubectl get svc node-probe -n helmissions         # PORT(S) 9100/TCP
   ```
5. Run `check` in the game.
