# Duplicate Port Names

## What broke
Inside `{{- range .Values.ports }}` the Service template used a hard-coded `name: http` and only took the port
number from the list item. With one entry that is harmless; with three entries the Service had three ports named
`http`, and Kubernetes requires port names to be unique within a Service (they are how `targetPort` names and
EndpointSlices tell ports apart).

## Why Helm behaves this way
`range` repeats its body once per item and rebinds the dot to that item, so everything that should differ between
iterations must be read from `.` - a literal inside the loop is simply repeated. Helm only produces text; it cannot
know that port names must be unique. The rule is enforced by the API server, so `helm template`/`helm lint` are
happy and the failure only shows up at install time - in Helm 4 as a server-side apply error, in Helm 3 as a
client-side or API validation error with the same `Duplicate value` wording.

## The fix
Read the name from the item (`name: {{ .name }}`). Because one list feeds both the Deployment and the Service, the
names stay in sync and `targetPort: {{ .name }}` resolves to the matching container port.

## In real life
This is the classic result of "I generalised this block into a loop" - the first version had one port, the loop
copied one line too few. Also note that a *failed install* leaves a failed release record: re-running `helm install`
then reports `cannot reuse a name that is still in use`; use `helm upgrade --install` or `helm uninstall` first.

## Commands worth remembering
- `helm template ./chart -s templates/service.yaml` - check one rendered object
- `helm upgrade --install <rel> ./chart` - idempotent deploy that also replaces a failed first attempt
- `kubectl get endpointslices -n <ns> -l kubernetes.io/service-name=<svc> -o yaml` - how ports are named downstream

## Common mistakes
- Trimming the ports list until the error goes away - the admin and metrics ports then silently disappear.
- Making names unique by hand-numbering (`http-1`, `http-2`) without updating `targetPort`.
- Forgetting that the dot inside `range` is the item: `.Values.x` inside the loop no longer works, use `$.Values.x`.

## Helm 3 vs Helm 4
Helm 4 applies manifests server-side, so the error is prefixed with `server-side apply failed for object ...`.
The failed install is recorded as a `failed` release in both versions.
