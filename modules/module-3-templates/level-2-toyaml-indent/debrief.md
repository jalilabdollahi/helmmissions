# Mis-indented Resources

## What broke
`{{- toYaml .Values.resources | nindent 10 }}` emitted `limits:` and `requests:` at the same indentation as the
`resources:` key above it. In YAML, structure *is* indentation: keys at the same column are siblings, so the
container suddenly had unknown fields called `limits` and `requests`, and `resources:` itself was null.

## Why Helm behaves this way
Helm templates are text. `toYaml` turns a values map into a block of YAML lines, but it knows nothing about where
you are placing it. The `indent`/`nindent` functions are how *you* tell Helm the column to place the block at.
Helm does not check that the rendered text makes sense for Kubernetes - the client-side render is happy, and the
real validation happens when the manifest reaches the API server. Helm 4 applies manifests with server-side
apply, whose schema-aware merge rejects unknown fields with `field not declared in schema` (Helm 3 reports
`unknown field` from client-side validation instead).

## The fix
Count the columns: `resources:` is at 10 spaces, so its children belong at 12 - `nindent 12`. A good habit is
to look at the rendered output of `helm template` with the `-s templates/deployment.yaml` flag and check the
staircase of the YAML by eye.

## In real life
This happens when a block is moved between templates (a container becomes an init container, a Deployment
becomes a StatefulSet) and the pasted `nindent` number is not updated. Without resources, pods run as BestEffort
and are the first to be evicted, so some teams "fix" the failure by deleting the block, which hides the real
bug. Linting does not catch it: `helm lint` only parses the text, and `helm template` happily prints it.
`helm template --validate` or a `--dry-run=server` against a real cluster, or kubeconform in CI, would.

## Commands worth remembering
- `helm template geoip ./geoip -s templates/deployment.yaml` - render one template
- `helm template ... --validate` - validate the output against the live API
- `kubectl explain pod.spec.containers.resources` - what the schema expects

## Common mistakes
- Removing the `resources` block to get the install through - the pod then has no limits at all.
- Using `indent` where `nindent` is needed (or vice versa) and ending up with glued or missing newlines.
- Changing values.yaml: the data was correct, the placement was wrong.

## Helm 3 vs Helm 4
On Helm 3 the same chart fails with a client-side `unknown field "limits" in io.k8s.api.core.v1.Container` style
error; on Helm 4 the server-side apply message shown in this level appears. Either way `helm template` alone
looks fine, so check the rendered indentation yourself.
