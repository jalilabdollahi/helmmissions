# Name Rejected - Walkthrough

1. Run the pipeline script and read the error:
   ```bash
   ./deploy.sh
   # Error: INSTALLATION FAILED: release name check failed: release name "Shop_Frontend":
   #   invalid release name, must match regex ^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]...
   ```
2. The regex is the DNS-1123 subdomain rule: lowercase alphanumerics and `-` (dots allowed between
   labels), starting and ending with an alphanumeric, at most 53 characters. `Shop_Frontend` breaks it twice:
   the capital letters and the underscore.
3. Fix the name inside the script - the script is what the pipeline runs, so a hand-typed install
   would only hide the problem:
   ```bash
   helm install shop-frontend ./storefront --namespace helmissions --wait --timeout 120s
   ```
4. Run it and verify:
   ```bash
   ./deploy.sh
   helm list -n helmissions
   kubectl get pods -n helmissions
   ```
5. Run `check` in the game.
