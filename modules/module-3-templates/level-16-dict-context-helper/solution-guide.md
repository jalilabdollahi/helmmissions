# Helper Needs A Dict - Walkthrough

1. `helm template mailer ./mailer` fails inside `mailer.fullname`: `nil pointer evaluating interface {}.Release`.
2. `templates/_helpers.tpl` documents the calling convention: `include "mailer.fullname" (dict "ctx" $ "component" "api")`.
   The helpers read `.ctx.Release.Name` and `.component`.
3. `grep -n include mailer/templates/*.yaml` shows that the callers pass `.` - the helper's argument has no `ctx` key.
4. Replace each call with the dict form, using `api` in api.yaml and `worker` in worker.yaml (8 calls in total, including the Service).
5. `helm template mailer ./mailer | grep -E 'name: mailer|component'` should show `mailer-api` and `mailer-worker`.
6. `helm install mailer ./mailer -n helmissions --wait`.
