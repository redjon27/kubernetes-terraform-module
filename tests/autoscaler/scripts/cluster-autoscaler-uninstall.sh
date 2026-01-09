#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
REGION="${2:-eu-central-1}"
TF_DIR="envs/${ENV}"

CLUSTER_NAME="$(cd "${TF_DIR}" && terraform output -raw cluster_name 2>/dev/null || true)"
if [[ -z "${CLUSTER_NAME}" ]]; then
  echo "ERROR: cluster_name output empty. Run terraform apply in ${TF_DIR} first."
  exit 1
fi

aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER_NAME}"

helm uninstall cluster-autoscaler -n kube-system || true
kubectl -n kube-system delete sa cluster-autoscaler || true

echo "✅ Removed Cluster Autoscaler for env=${ENV}"
