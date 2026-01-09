#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
REGION="${2:-eu-central-1}"
TF_DIR="envs/${ENV}"

ROLE_ARN="$(cd "${TF_DIR}" && terraform output -raw cluster_autoscaler_role_arn 2>/dev/null || true)"
CLUSTER_NAME="$(cd "${TF_DIR}" && terraform output -raw cluster_name 2>/dev/null || true)"

if [[ -z "${CLUSTER_NAME}" ]]; then
  echo "ERROR: cluster_name output empty. Run terraform apply in ${TF_DIR} first."
  exit 1
fi

if [[ -z "${ROLE_ARN}" ]]; then
  echo "Cluster Autoscaler DISABLED for env=${ENV} (role_arn empty)."
  echo "Set enable_cluster_autoscaler=true in ${TF_DIR}/terraform.tfvars and run terraform apply."
  exit 0
fi

aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER_NAME}"

kubectl -n kube-system create sa cluster-autoscaler || true
kubectl -n kube-system annotate sa cluster-autoscaler \
  eks.amazonaws.com/role-arn="${ROLE_ARN}" --overwrite

helm repo add autoscaler https://kubernetes.github.io/autoscaler >/dev/null 2>&1 || true
helm repo update >/dev/null

helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  -n kube-system \
  --set autoDiscovery.clusterName="${CLUSTER_NAME}" \
  --set awsRegion="${REGION}" \
  --set rbac.serviceAccount.create=false \
  --set rbac.serviceAccount.name="cluster-autoscaler"

echo "✅ Installed Cluster Autoscaler for env=${ENV} (cluster=${CLUSTER_NAME})"
