# Restricted Pod Security — Walkthrough

1. `kubectl get pods -n helmissions` is empty. `kubectl describe rs -n helmissions` shows
   `violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false ..., unrestricted capabilities ...,
   runAsNonRoot != true ..., seccompProfile ...`.
2. `kubectl get ns helmissions --show-labels` shows `pod-security.kubernetes.io/enforce=restricted` — leave it.
3. In `audit-gateway/values.yaml`:
   ```yaml
   podSecurityContext:
     runAsNonRoot: true
     runAsUser: 101
     seccompProfile: {type: RuntimeDefault}
   containerSecurityContext:
     allowPrivilegeEscalation: false
     capabilities: {drop: ["ALL"]}
   ```
4. The error also names `wait-config`, the init container. Pod-level settings cover runAsNonRoot and seccomp, but
   not the container-level ones: add to that init container in `templates/deployment.yaml`
   `securityContext: {allowPrivilegeEscalation: false, capabilities: {drop: ["ALL"]}}`.
5. `helm upgrade audit-gateway ./audit-gateway -n helmissions --wait`; run `check`.
