# Invisible Tabs

## What broke
`values.yaml` had TAB characters as indentation (pasted from a wiki). YAML forbids tabs for indentation, so the parser stops
at the first tab: `found character that cannot start any token`. Because the chart's default `values.yaml` is loaded before
anything else, the chart cannot even be installed, linted or templated.

## Why Helm behaves this way
Helm reads values with a YAML parser, and YAML's grammar says indentation is made of spaces only - tabs can be used inside
a line, never to express structure. The error is reported with a line number but the offending character is invisible, so
people stare at perfectly aligned text for a long time. Helm also parses `--values` files the same way: a broken file fails
early, before any template renders.

## The fix
Replace the tabs by spaces and keep the structure. Verify with `helm lint`. Set your editor to insert spaces for YAML, and
add an `.editorconfig` (`indent_style = space` for `*.yaml`) or a `yamllint` step to catch it before a human does.

## In real life
Tabs sneak in via copy/paste from wikis, PDFs and chat tools, via editors configured for Makefiles, and via heredocs in
CI scripts. The damage is not limited to Helm: Kubernetes manifests, GitHub Actions, Docker Compose and Ansible all choke on
them. A `yamllint` or `helm lint` job in the pull request pipeline turns this into a 5-second fix.

## Commands worth remembering
- `cat -A file.yaml` / `grep -nP '\t' file.yaml` - reveal tabs
- `helm lint ./chart` - parses values and templates without a cluster
- `yq e '.' values.yaml` or `python3 -c 'import yaml,sys; yaml.safe_load(open(sys.argv[1]))' values.yaml` - quick parse test

## Common mistakes
- Deleting the offending block and re-supplying the values with `--set`: the broken file stays in the repository.
- Replacing the tab with a single space: the nesting changes and the values end up under the wrong key.
- Mixing tabs and spaces inside the same file after a "partial" cleanup.

## Helm 3 vs Helm 4
Both fail on tab indentation. Helm 4 words the failure as `failed to parse values.yaml: cannot unmarshal yaml document ...`
in some code paths, but the underlying message `found character that cannot start any token` is the same.
