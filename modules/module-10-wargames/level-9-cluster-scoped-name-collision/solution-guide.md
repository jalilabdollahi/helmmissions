# Solution guide - Two Teams, One ClusterRole

1. Re-run `helm install team-b ...` and read: `ClusterRole "helmissions-pod-reader" in namespace "" exists and cannot be imported into the current release:
   ... key "meta.helm.sh/release-namespace" must equal "helmissions-team-b": current value is "helmissions-team-a"`.
2. `helm template x ./collector -n y | grep -B2 -A6 'kind: Cluster'` plus `grep -r priorityClass`: ClusterRole, ClusterRoleBinding and PriorityClass all use fixed names.
3. Add `templates/_helpers.tpl` with `collector.scope` = `{{ .Release.Namespace }}-{{ .Release.Name }}`; name the three objects `{{ include "collector.scope" . }}-...`
   and use the same name in `priorityClassName` and the binding's `roleRef`.
4. In the ClusterRoleBinding replace the hard-coded `helmissions-team-a` with `{{ .Release.Namespace }}`.
5. `bash install-teams.sh`: team-a is upgraded (old shared objects deleted, new scoped ones created), team-b installs.
6. Verify: `kubectl auth can-i list pods -A --as=system:serviceaccount:helmissions-team-b:collector` -> yes; both status pages `pods-api=200`.
