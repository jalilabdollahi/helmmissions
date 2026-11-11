# The Disappearing Deployment - Walkthrough

1. `helm status status -n helmissions` is `deployed`, but `kubectl get all -n helmissions` shows only `service/status`.
2. `helm get manifest status -n helmissions` shows a single block that starts with the Deployment's fields and then
   repeats `apiVersion`, `kind`, `metadata`, `spec` for the Service, with no `---` between them.
3. YAML allows duplicate keys in practice (the last value wins), so the two documents were merged into one object with
   the Service's `kind`, `metadata` and `spec` - the Deployment silently disappeared.
4. Add the document separator on its own line between the objects:
   ```
   ...resources: {{- toYaml ... }}
   ---
   apiVersion: v1
   kind: Service
   ```
   (or move the Service to its own template file).
5. `helm template status ./status-page | grep '^kind:'` should list Deployment and Service.
6. `helm upgrade status ./status-page -n helmissions --wait`.
