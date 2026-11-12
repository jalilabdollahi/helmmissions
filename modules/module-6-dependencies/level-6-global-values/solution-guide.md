# One Setting For All Subcharts — Walkthrough

1. Observe the symptom:
   ```bash
   kubectl get deploy -n helmissions -o custom-columns=N:.metadata.name,R:.spec.template.spec.containers[0].env[0].value
   helm get values telemetry -n helmissions --all
   ```
   The computed values have `global.environment` but no `global.region`; `region` is a loose top-level value.
2. Find who reads it:
   ```bash
   grep -rn "Values\.\(global\.\)\?region" telemetry collector exporter
   # all templates use .Values.global.region
   ```
3. Move the value into the `global:` block of `telemetry/values.yaml`:
   ```yaml
   global:
     environment: production
     region: eu-west-1
   ```
4. Upgrade and verify:
   ```bash
   helm upgrade telemetry ./telemetry -n helmissions --wait
   kubectl describe pod -n helmissions -l app.kubernetes.io/instance=telemetry | grep REGION
   ```
5. Run `check`.
