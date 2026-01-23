module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = var.name
  cluster_version = var.k8s_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  enable_irsa = true

  eks_managed_node_groups = {
    general = {
      instance_types = var.node_group.instance_types
      capacity_type  = var.node_group.capacity_type

      desired_size = var.node_group.desired_size
      min_size     = var.node_group.min_size
      max_size     = var.node_group.max_size

      disk_size = var.node_group.disk_size

      labels = {
        role = "general"
      }
    }
  }

  tags = local.tags
}
