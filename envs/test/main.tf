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
  node_group = var.node_group

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  tags = {
    Environment = "test"
  }
}