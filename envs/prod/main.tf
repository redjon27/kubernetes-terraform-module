provider "aws" {
  region = var.aws_region
}

module "platform" {
  source = "../../modules/eks-platform"

  name               = var.name
  k8s_version        = var.k8s_version
  azs                = var.azs
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  instance_types     = var.instance_types
  node_group         = var.node_group

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  tags = {
    Environment = "prod"
  }
}

module "cluster_autoscaler_iam" {
  count  = var.enable_cluster_autoscaler ? 1 : 0
  source = "../../modules/cluster-autoscaler-iam"

  cluster_name      = module.platform.cluster_name
  oidc_provider_arn = module.platform.oidc_provider_arn
  oidc_provider_url = module.platform.oidc_provider_url
}

output "cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for Cluster Autoscaler (empty when disabled)"
  value       = var.enable_cluster_autoscaler ? module.cluster_autoscaler_iam[0].role_arn : ""
}