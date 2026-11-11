# The Password Changes Every Deploy - Walkthrough

1. `helm history ledgerdb -n helmissions` shows two revisions; the Secret's password differs between them
   (`helm get manifest ledgerdb --revision 1` vs `--revision 2`). Do not upgrade the unfixed chart again.
2. `templates/secret.yaml` generates `randAlphaNum` inline. Each upgrade re-renders the template, so each upgrade
   produces a fresh random string, and the `checksum/credentials` annotation on the Deployment then restarts the pod.
3. Make the template idempotent with `lookup`:
   ```
   {{- $name := printf "%s-credentials" .Release.Name }}
   {{- $existing := lookup "v1" "Secret" .Release.Namespace $name }}
   {{- $password := randAlphaNum (int .Values.auth.passwordLength) }}
   {{- if and $existing $existing.data }}
   {{- $password = index $existing.data "password" | b64dec }}
   {{- end }}
   ```
   and render `password: {{ $password | b64enc | quote }}`.
4. First install (and `helm template`) has nothing to look up, so a new random value is generated; every later upgrade
   finds the Secret and reuses its value.
5. `helm upgrade ledgerdb ./ledger-db -n helmissions --wait` - the password in the live Secret is the one that was
   already registered with billing (compare its sha256 with `kubectl get cm registered-credentials -o yaml`).
