# Solution guide - Wrong Namespace DNS

1. `kubectl exec deploy/orders-web -n helmissions-web -- cat /etc/resolv.conf`: nameservers are the node's, not the cluster DNS
   (`10.96.0.10`) and there are no `svc.cluster.local` search domains. The pod has `dnsPolicy: Default`
   (`kubectl get deploy orders-web -n helmissions-web -o yaml | grep dnsPolicy`).
2. Set `network.dnsPolicy: ClusterFirst` in `orders-web/values.yaml`. Now short names work only inside the same namespace:
   `nslookup orders-api` from the web pod fails; `nslookup orders-api.helmissions-api` works.
3. Set `ordersApi.host: orders-api.helmissions-api.svc.cluster.local` (or `orders-api.helmissions-api`).
   The error changes from `bad address` to `Connection refused`: DNS is fine, the Service forwards to the wrong port.
4. `kubectl get svc,endpointslices -n helmissions-api` / `kubectl describe svc orders-api`: `TargetPort: 8081`,
   but the container listens on 8080. Set `service.targetPort: 8080` in `orders-api/values.yaml`.
5. `bash deploy.sh`; verify with `kubectl run probe -it --rm --image=curlimages/curl:8.10.1 --restart=Never -n helmissions-web -- curl -s http://orders-web/cgi-bin/dashboard`.
