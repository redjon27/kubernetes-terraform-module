aws_region  = "eu-central-1"
name        = "redi-eks-prod"
k8s_version = "1.34"

azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

vpc_cidr           = "10.30.0.0/16"
instance_types = ["t3.large"]
enable_nat_gateway = false
enable_vpc_endpoints = true
cluster_endpoint_public_access  = false
cluster_endpoint_private_access = true
enable_cluster_autoscaler = false

node_group = {
  desired_size   = 2
  min_size       = 2
  max_size       = 6
  instance_types = ["m6i.large"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 50
}

irsa_roles = {
  app = {
    namespace      = "default"
    serviceaccount = "app-sa"

    policy = {
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["sts:GetCallerIdentity"]
        Resource = "*"
      }]
    }
  }

  ebs_csi = {
    namespace      = "kube-system"
    serviceaccount = "ebs-csi-controller-sa"

    policy_arns = [
      "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    ]

    policy = {
      Version   = "2012-10-17"
      Statement = []
    }
  }
}
