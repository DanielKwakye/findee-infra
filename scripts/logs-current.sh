#!/bin/sh
set -eu

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required and must be configured for your Kubernetes cluster." >&2
  exit 1
fi

# Stream logs until interrupted with Ctrl+C.
exec kubectl logs --namespace findee --follow deployment/findee-deployment --tail=100
