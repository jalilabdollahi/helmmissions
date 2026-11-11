# Nil Pointer In The Cache Block - Walkthrough

1. Reproduce:
   ```bash
   helm template profile-svc ./profile-svc -f values-staging.yaml
   # nil pointer evaluating interface {}.redis
   ```
2. `values-staging.yaml` has no `cache:` key, `values-prod.yaml` has one. The template reads
   `.Values.cache.redis.host` unconditionally (`profile-svc/templates/configmap.yaml`).
3. Guard the optional block in the template:
   ```yaml
   data:
     LOG_LEVEL: {{ .Values.logLevel | quote }}
     {{- with .Values.cache }}
     {{- with .redis }}
     CACHE_HOST: {{ .host | quote }}
     CACHE_PORT: {{ .port | default 6379 | quote }}
     {{- end }}
     {{- end }}
   ```
   `with` skips its body when the value is nil/empty, so no key is looked up on nil.
4. Verify both worlds:
   ```bash
   helm template profile-svc ./profile-svc -f values-staging.yaml | grep -A4 'data:'
   helm template profile-svc ./profile-svc -f values-prod.yaml    | grep CACHE
   ```
5. Install: `helm install profile-svc ./profile-svc -n helmissions -f values-staging.yaml`, then run `check`.
