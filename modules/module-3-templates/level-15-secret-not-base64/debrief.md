# illegal base64 data

## What broke
The Secret template wrote the provider key into `data:` as plain text. Kubernetes defines `Secret.data` as a map of
*base64-encoded* strings; when the API server decoded `sk-test-9f41c7a2d8` it hit a character that is not in the base64
alphabet and rejected the object: `illegal base64 data at input byte 2`.

## Why Helm behaves this way
Helm just prints text; it has no idea that `data` is special. The two places that hold secret material differ:
`data` (base64, what is stored in etcd) and `stringData` (a write-only convenience field - plain text that the API
server encodes into `data`). Helm provides the `b64enc` function (and `b64dec` for the other direction). Keep in mind
that a value that happens to be valid base64 (`abcd`) would be accepted and silently decoded to different bytes - the
error here appeared only because the key had a `-`.

## The fix
`{{ .Values.provider.apiKey | b64enc | quote }}` in `data`, or `stringData` with the plain value. Both give the same
stored Secret. `stringData` has one gotcha: if a key is present in both fields, `stringData` wins, and
`helm get manifest` shows the plain text, whereas `data` shows only the encoded form (still not encrypted!).

## In real life
Secrets rendered from values mean the plain value lives in the values file, in Helm's release storage (itself a
Secret) and in CI logs. Production charts therefore usually reference an existing Secret (`existingSecret:`), use
External Secrets or Sealed Secrets, or inject values from a vault at deploy time. Where charts do render Secrets, a
common bug is double-encoding (`b64enc` on a value that is already encoded) - the pod then receives the base64 text.

## Commands worth remembering
- `kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 -d` - read a secret value back
- `helm template ./chart -s templates/secret.yaml` - see what will be sent
- `echo -n value | base64` - mind the `-n`; a trailing newline becomes part of the secret

## Common mistakes
- Encoding the key by hand in values.yaml: works until someone sets the key the normal (plain) way.
- Piping to `b64enc` twice, or encoding with `echo` (trailing newline) and pasting the result.
- Forgetting `quote`, so a numeric-looking secret turns into a YAML number.

## Helm 3 vs Helm 4
The text differs: Helm 4 shows the server-side apply form `failed to convert new object ... illegal base64 data`, while
Helm 3 shows `json: cannot unmarshal ...` or the decode error from client-side validation. The fix is the same.
