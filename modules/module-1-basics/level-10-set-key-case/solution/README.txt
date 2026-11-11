Slack, #billing-oncall:
  dev:  "I scaled billing to 4 workers before the month-end run:
         helm upgrade billing ./billing --set replicacount=4 -n helmissions"
  dev:  "helm said the upgrade succeeded but I still only see one worker pod. ???"
