# Switch Back To Blue - Walkthrough

1. Check the Service and the pods:
   ```bash
   kubectl get svc ticket-booking -n helmissions -o jsonpath='{.spec.selector}'    # color: green
   kubectl get pods -n helmissions -L color                                         # green: ImagePullBackOff, blue: Running
   ```
2. In `values-prod.yaml`, change only the colour (keep the `green:` block - it is what you want to debug):
   ```yaml
   activeColor: blue
   green:
     replicas: 2
     tag: v1.99.0
   ```
3. Deploy through the pipeline script (no `--wait`, green would never become ready):
   ```bash
   bash ci/deploy.sh
   helm history ticket-booking -n helmissions        # revision 3
   ```
4. Verify:
   ```bash
   kubectl get endpointslices -n helmissions
   kubectl get deploy -n helmissions                 # blue 2/2, green 0/2 (kept for debugging)
   ```
5. Run `check`.
