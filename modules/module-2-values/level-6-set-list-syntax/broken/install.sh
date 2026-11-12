#!/bin/bash
# What the runbook says to run for the new DNS search domains (does not work):
helm install mesh-client ./mesh-client -n helmissions \
  --set dnsSearch=payments.svc.cluster.local,corp.internal
