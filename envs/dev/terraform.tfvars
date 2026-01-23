aws_region  = "eu-central-1"
name        = "redi-eks-dev"
k8s_version = "1.34"

azs      = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
vpc_cidr = "10.10.0.0/16"

enable_nat_gateway = true

cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true
instance_types                  = ["t3.large"]
enable_cluster_autoscaler       = false

node_group = {
  desired_size   = 1
  min_size       = 1
  max_size       = 2
  instance_types = ["t3.large"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 30
}

irsa_roles = {
  app = {
    namespace      = "default"
    serviceaccount = "app-sa"

    policy_arns = []

    policy = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["sts:GetCallerIdentity"]
          Resource = "*"
        }
      ]
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
