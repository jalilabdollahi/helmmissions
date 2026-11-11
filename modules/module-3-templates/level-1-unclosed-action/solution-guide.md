# Unclosed Action - Walkthrough

1. Reproduce:
   ```bash
   helm install pressroom ./pressroom -n helmissions
   # Error: INSTALLATION FAILED: parse error at (pressroom/templates/configmap.yaml:13): unexpected "}" in operand
   ```
2. Parse errors happen before Helm talks to the cluster, so you can iterate locally:
   ```bash
   helm template pressroom ./pressroom      # same error, no cluster needed
   helm lint ./pressroom
   ```
3. Open `pressroom/templates/configmap.yaml` at line 13. The heading reads
   `<h1>{{ .Values.site.name }</h1>` - the action is closed with one brace instead of two.
4. Fix it so it reads `<h1>{{ .Values.site.name }}</h1>`. Do not replace it with literal text: the name must
   keep coming from `values.yaml`.
5. Verify and install:
   ```bash
   helm lint ./pressroom
   helm template pressroom ./pressroom | head -30
   helm install pressroom ./pressroom -n helmissions --wait
   kubectl get pods -n helmissions
   ```
6. Run `check` in the game.
