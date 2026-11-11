# Literal Braces - Walkthrough

1. `kubectl logs deploy/orders-api -n helmissions` prints `orders-api talking to {{ .Release.Name }}-db:5432`.
2. `helm get values orders -n helmissions --all` shows `database.host: '{{ .Release.Name }}-db'`; the template just
   copies it: `value: {{ .Values.database.host | quote }}`.
3. Values are data. Helm renders template *files*, not strings found inside values. `tpl` evaluates a string as a
   template: `{{ tpl .Values.database.host . | quote }}`.
4. Check with two release names:
   ```bash
   helm template orders ./orders-api | grep -A1 DB_HOST
   helm template qa-7 ./orders-api | grep -A1 DB_HOST
   ```
5. `helm upgrade orders ./orders-api -n helmissions --wait` and `kubectl get pods -n helmissions`.
