# The Empty Timeout

## What broke
The ConfigMap template reads `{{ .Values.http.timeout }}`, but `values.yaml` only defines `http.retries`. The key does not
exist, so Helm rendered an empty string: `FETCH_TIMEOUT=`. The application then refused to start with an empty timeout and
the pod crash-looped, while Helm happily reported `deployed`.

## Why Helm behaves this way
Go templates return "no value" for a missing map key, and Helm turns that into an empty string instead of failing (the
`<no value>` marker you may remember from Go itself is stripped from the output). Helm cannot know whether an absent key is a
bug or an intentional "not configured". It leaves that decision to the chart: use `default`, `required` (to fail loudly with a
clear message), or declare the key with a value in `values.yaml`.

## The fix
`{{ .Values.http.timeout | default 30 }}`. Note that `default` also replaces `0`, `""`, `false` and empty lists, so if `0` is a
valid user choice use `hasKey`/`ternary` or `dig` instead. For values that must be supplied use `{{ required "http.timeout is required" ... }}`.

## In real life
Charts grow. A new template starts using a value that only the author's local values file defines; every other
environment renders blanks. Typical victims: timeouts, ports, replica counts and URLs, which turn into `timeout: ` (YAML null)
or `port: ` and make the API server or the app reject them. Defaults in templates are the safety net that makes charts
safe to upgrade without anyone editing their values.

## Commands worth remembering
- `helm template ./chart | grep -n 'KEY'` - quick look at one rendered value
- `helm template ./chart --set a.b=null` - `null` removes a default key, a handy way to test "unset"
- `helm lint ./chart --strict` - flags some, but not all, missing values

## Common mistakes
- Adding the value to `values.yaml` only: it hides the problem until someone overrides the whole `http` map or sets it to null.
- Using `--set http.timeout=30` on the command line: the chart stays fragile and the next pipeline forgets the flag.
- Using `default` for values where `0` or `false` are legitimate.

## Helm 3 vs Helm 4
On both versions a missing key renders as an empty string (the literal text `<no value>` is not emitted). Reading a key through a
missing parent map (`.Values.cache.redis.host` without `cache`) is a different failure: a nil-pointer error.
