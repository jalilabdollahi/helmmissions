# Unauthorized Pull

## What broke
The image lives in a registry that requires HTTP basic authentication, and the pod spec carried no `imagePullSecrets`.
The kubelet (through containerd) asked the registry for the image anonymously and got `401 Unauthorized`, which it reports as
`pull access denied ... authorization failed: no basic auth credentials`, followed by `ErrImagePull` and `ImagePullBackOff`.
The Helm release itself was fine.

## Why Helm behaves this way
Helm has no concept of registry credentials for *workloads*: `helm registry login` authenticates the Helm client when it
pulls a chart, but the images in the chart are pulled by the node. Node-side credentials come from a Secret of type
`kubernetes.io/dockerconfigjson` in the pod's namespace, referenced by `imagePullSecrets` on the pod or on its ServiceAccount.
The Secret's `auths` key must match the registry host in the image reference (`localhost:5002`). Kubernetes also re-checks
credentials for images that are already cached on the node, so a pod without access cannot reuse another pod's pull.

## The fix
Create a docker-registry Secret for the registry, expose it as `imagePullSecrets` in values (the chart template already
supports it), and upgrade. Keep the registry credentials out of values and out of git — the values only name the Secret.

## In real life
Pull secrets expire (rotated robot tokens, ECR/GCR short-lived tokens), live in one namespace only (so every new namespace
breaks the same way), and are forgotten in subcharts and Jobs. Teams then "fix" it by making the registry public, copying
the image to an open registry, or baking credentials into node images — each of which turns a one-line misconfiguration
into a supply-chain exposure. Prefer a read-only robot account per environment, an external secrets operator for rotation,
and `imagePullSecrets` on the ServiceAccount used by all workloads of a namespace.

## Commands worth remembering
- `kubectl create secret docker-registry NAME --docker-server=HOST --docker-username=U --docker-password=P`
- `kubectl get secret NAME -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq`
- `kubectl describe pod POD` — the pull error is in Events
- `kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"NAME"}]}'`

## Common mistakes
- Creating the Secret in the wrong namespace, or for a different server name than the image's registry host.
- Putting the password in values.yaml (`--set imagePullSecrets...password`) so it ends up in `helm get values`.
- Expecting `helm registry login` to give the nodes access to images.
- Working around the error by pushing the image to a public registry.
