# Misaligned Labels

## What broke
`labels: {{ include "ledger-recon.labels" . | indent 4 }}` renders as `labels:` followed by four spaces and then the
first label on the *same* line, with the remaining labels on the following lines. YAML sees a key with an inline value
(`app.kubernetes.io/name: ledger-recon`) and then more keys indented under it - hence "mapping values are not
allowed in this context".

## Why Helm behaves this way
Helm does not understand YAML while it renders: a template produces text, and only afterwards the text is parsed. A
helper's output is a multi-line string; `indent N` adds N spaces in front of every line of it, and `nindent N` does
the same but also starts with a newline. That one character is the difference. The idiom you will see in every chart
is therefore:

    labels:
      {{- include "x.labels" . | nindent 4 }}

where `{{-` trims the whitespace before the action so the newline from `nindent` is the only one left.

## The fix
Use `nindent` and put the action on its own line. If you must write `labels:` and the call on one line, you need
an explicit line break in the template instead (`labels:` newline, then `{{ ... | indent 4 }}` at column 0).

## In real life
`indent` is right for block scalars where the first line already follows a `key: |` header, `nindent` is right for
maps and lists nested under a key. Mixing them up is the most common source of "mapping values are not allowed"
and "did not find expected key" errors in chart reviews. Scheduled workloads such as CronJobs add insult to injury:
nothing fails at runtime, the job just never exists until someone notices a missing nightly report.

## Commands worth remembering
- `helm template ./chart --debug` - prints the rendered text even when it is not valid YAML
- `helm template ./chart -s templates/cronjob.yaml` - render one file
- `kubectl get cronjob -n <ns> --show-labels`

## Common mistakes
- Adding the missing newline by hand but leaving the odd indentation: some combinations parse but nest labels one
  level too deep.
- Typing the labels by hand: it works, but the label set then drifts from the helper used by every other object.
- Using `nindent` and ALSO leaving the action on the `labels:` line - you get a blank value (`labels:` + newline) that
  parses but is easy to misread.

## Helm 3 vs Helm 4
Both parse the rendered manifest as YAML and report the same libyaml-style message. Helm 4 reports a bad manifest
before contacting the cluster, so no release record is created.
