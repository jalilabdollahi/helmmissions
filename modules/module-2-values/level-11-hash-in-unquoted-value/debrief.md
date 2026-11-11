# The Hash That Ate My Password

## What broke
`password: Harbor Light #2024` is, to a YAML parser, the plain scalar `Harbor Light` followed by the comment `#2024`.
The password stored in the Secret was therefore truncated, the init container compared the wrong value, and the pod never got
past `Init`. Helm did exactly what it was told - the loss happened inside the YAML parser, before templates ran.

## Why Helm behaves this way
Values files are YAML, and YAML has a small set of characters with special meaning in unquoted scalars: ` #` (comment),
`: ` (mapping), a leading `@`, `*`, `&`, `!`, `%`, `|`, `>`, `-` or `[`/`{`. A `#` only starts a comment when it is preceded
by whitespace (`abc#def` is fine, `abc #def` is not), which makes the bug depend on the exact password. Quoting (`"..."` or `'...'`)
turns the whole thing into a string. Helm never sees the comment, so `helm get values` shows the truncated string and nothing warns you.

## The fix
Quote the value: `password: "Harbor Light #2024"`. In double quotes `\` and `"` need escaping, in single quotes only `'` (written `''`).
For CI, `--set-string 'db.password=...'` bypasses YAML entirely (mind the commas and shell quoting).

## In real life
Passwords, tokens and connection strings are the values most likely to contain `#`, `:`, `@`, `*`, `{` or `!`. Rotation pipelines
that write values files with `echo "password: $PW" >> values.yaml` are a classic source of this bug. Better: do not put real secrets in
values files at all - use `existingSecret` references, an external secret operator (External Secrets, Vault, SOPS) or `--set-file`.
Always quote string values you did not write by hand.

## Commands worth remembering
- `helm get values <rel>` - the values after YAML parsing: compare with what you wrote
- `kubectl get secret <name> -o jsonpath='{.data.KEY}' | base64 -d` - decode a Secret key
- `helm template ./chart | grep -A3 'kind: Secret'` - preview Secret data (base64) before deploying

## Common mistakes
- Patching the Secret with kubectl: the next `helm upgrade` writes the truncated value again.
- Assuming `#2024` alone (without a space) is also truncated - it is not, so "it worked for the old password".
- Quoting in the shell but not in YAML (`echo "password: $PW"` still produces an unquoted scalar).

## Helm 3 vs Helm 4
Identical in both: values are parsed by YAML before Helm's own logic runs.
