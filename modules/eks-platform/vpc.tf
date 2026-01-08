module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = var.name
  cidr = var.vpc_cidr

  azs = var.azs

  # Generate subnets dynamically from the VPC CIDR
  # Assumes var.vpc_cidr is a /16 (e.g. 10.10.0.0/16)
  # /16 -> /20 => newbits = 4
  # 0..2 public, 3..5 private (3 AZs)
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 4, 0),
    cidrsubnet(var.vpc_cidr, 4, 1),
    cidrsubnet(var.vpc_cidr, 4, 2),
  ]

  private_subnets = [
    cidrsubnet(var.vpc_cidr, 4, 3),
    cidrsubnet(var.vpc_cidr, 4, 4),
    cidrsubnet(var.vpc_cidr, 4, 5),
  ]

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}
