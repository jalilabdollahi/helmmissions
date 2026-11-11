#!/bin/bash
# Deploy profile-svc to staging
helm install profile-svc ./profile-svc -n helmissions -f values-staging.yaml
