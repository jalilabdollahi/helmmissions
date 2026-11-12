# Required Means Required - Walkthrough

1. Reproduce:
   ```bash
   helm install docs-site ./docs-site -n helmissions
   # Error: ... ingressHost is required: set the public host name of the docs portal
   ```
2. See how the chart expects to be configured:
   ```bash
   helm show values ./docs-site        # ingressHost: ""   (comment: every environment must set its own)
   grep -n required docs-site/templates/*.yaml
   ```
3. The chart is shared, so do not hardcode the host in it. Create a values file for the environment,
   using the host in README.txt:
   ```yaml
   # values-staging.yaml
   ingressHost: docs.staging.helmissions.local
   ```
4. Install with it and check:
   ```bash
   helm install docs-site ./docs-site -n helmissions -f values-staging.yaml --wait
   helm get values docs-site -n helmissions
   kubectl get ingress -n helmissions
   ```
5. Run `check` in the game.
