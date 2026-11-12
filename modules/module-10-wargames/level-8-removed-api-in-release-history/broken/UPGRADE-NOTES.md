# edge-gateway 1.4.0 upgrade

The platform team upgraded the cluster to a Kubernetes release that dropped several long-deprecated API versions.
`edge-gateway` has been running on it since the old 1.x chart was installed (revisions 1 and 2 of the release).

Goal of the change window: release the 1.4.0 chart in this workspace (rate limit 200, autoscaling between 2 and 4 replicas)
as the next revision of the existing release `edge-gateway` in namespace `helmissions`. The gateway keeps serving
the whole time; the release history must be kept (the on-call rolls back from it).

`helm upgrade` has been refusing to do anything since the cluster upgrade. `mapkubeapis` is not available on this network.
Release records are Secrets named `sh.helm.release.v1.<release>.v<revision>` of type `helm.sh/release.v1`.
