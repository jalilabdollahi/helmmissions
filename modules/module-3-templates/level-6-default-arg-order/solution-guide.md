# Default Always Wins - Walkthrough

1. `kubectl get pods -n helmissions` shows ErrImagePull/ImagePullBackOff; the image is
   `traefik/whoami:v1.11-rc1`, which is the chart's `appVersion`, not the pinned `v1.10`.
2. `helm get values echo -n helmissions --all` confirms `image.tag: v1.10`. The value is right but unused.
3. In `templates/_helpers.tpl`: `default .Values.image.tag .Chart.AppVersion`. `default A B` returns B when B is
   non-empty, so the appVersion (always non-empty) wins every time.
4. Swap the arguments: `default .Chart.AppVersion .Values.image.tag` (or `.Values.image.tag | default .Chart.AppVersion`).
5. Verify the three cases:
   ```bash
   helm template echo ./echo-api | grep image:
   helm template echo ./echo-api --set image.tag=foo | grep image:
   helm template echo ./echo-api --set image.tag= | grep image:
   ```
6. `helm upgrade echo ./echo-api -n helmissions --wait`.
