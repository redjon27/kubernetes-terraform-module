resource "aws_security_group" "vpc_endpoints" {
  count       = local.vpc_endpoints_enabled ? 1 : 0
  name        = "${var.name}-vpc-endpoints"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

module "vpc_endpoints" {
  count   = local.vpc_endpoints_enabled ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.21"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = concat(
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids
      )
      tags = local.tags
    }

    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
      tags                = local.tags
    }

    ec2messages = {
      service             = "ec2messages"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
      tags                = local.tags
    }

    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
      tags                = local.tags
    }

    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
      tags                = local.tags
    }

    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
      tags                = local.tags
    }

    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
      tags                = local.tags
    }

    ec2 = {
      service             = "ec2"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
      tags                = local.tags
    }

    # recommended (ops)
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
      tags                = local.tags
    }
  }

  tags = local.tags
}
