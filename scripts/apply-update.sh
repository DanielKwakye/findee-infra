#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
infrastructure_dir="$script_dir/.."
env_file=${1:-/root/apps/findee/envs/env.prod}

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required and must be configured for your Kubernetes cluster." >&2
  exit 1
fi
if [ ! -r "$env_file" ]; then
  echo "Environment file not readable: $env_file" >&2
  exit 1
fi

namespace_manifest=$(kubectl create namespace findee --dry-run=client -o yaml)
printf '%s\n' "$namespace_manifest" | kubectl apply -f -

secret_manifest=$(kubectl create secret generic findee-env \
  --namespace findee \
  --from-env-file="$env_file" \
  --dry-run=client -o yaml)
printf '%s\n' "$secret_manifest" | kubectl apply --server-side \
  --field-manager=findee-env --namespace findee -f -
unset secret_manifest

kubectl apply --namespace findee \
  -f "$infrastructure_dir/k8s/deployment.yaml" \
  -f "$infrastructure_dir/k8s/service.yaml" \
  -f "$infrastructure_dir/k8s/ingress.yaml"

# Restart pods to pick up environment changes from the Secret.
kubectl rollout restart deployment/findee-deployment --namespace findee
kubectl rollout status deployment/findee-deployment \
  --namespace findee --timeout=120s

echo "Resources applied. Check status with: kubectl get deployments,pods,services,ingresses -n findee"
