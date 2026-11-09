#!/bin/sh
set -eu

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required and must be configured for your Kubernetes cluster." >&2
  exit 1
fi

# Show logs from the previous container instance after a restart.
exec kubectl logs --namespace findee deployment/findee-deployment --previous
