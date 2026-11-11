# Dots In Keys - Walkthrough

1. Inspect what the pods actually got:
   ```bash
   kubectl get deploy telemetry-agent -n helmissions -o jsonpath='{.spec.template.metadata.annotations}'
   # {"prometheus":"map[io/port:9100 io/scrape:true]"}
   helm get values telemetry-agent -n helmissions
   # podAnnotations:
   #   prometheus:
   #     io/port: 9100
   #     io/scrape: true
   ```
2. `--set` treats `.` as a path separator, so `prometheus.io/scrape` was split into nested maps.
3. Escape the dots (and quote the argument for the shell), or use a values file:
   ```bash
   helm upgrade telemetry-agent ./telemetry-agent -n helmissions \
     --set 'podAnnotations.prometheus\.io/scrape=true' \
     --set 'podAnnotations.prometheus\.io/port=9100'
   ```
   Values-file alternative (`values-metrics.yaml`):
   ```yaml
   podAnnotations:
     prometheus.io/scrape: "true"
     prometheus.io/port: "9100"
   ```
   then `helm upgrade ... -f values-metrics.yaml`.
4. Verify with the same `kubectl get deploy ... annotations` command, then `check`.
