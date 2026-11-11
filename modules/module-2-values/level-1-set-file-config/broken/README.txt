landing - marketing site
------------------------
site.conf   nginx server block owned by the marketing team (they edit it, we deploy it)
landing/    Helm chart; the server block ends up in a ConfigMap mounted at /etc/nginx/conf.d

Last deploy (run by a colleague):
  helm install landing ./landing -n helmissions --set siteConfig=./site.conf
