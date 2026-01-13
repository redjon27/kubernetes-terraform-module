locals {
  tags = merge(
    {
      ManagedBy = "terraform"
      Project   = var.name
    },
    var.tags
  )

  # Create VPC endpoints automatically when NAT is disabled (prod case)
  vpc_endpoints_enabled = var.enable_vpc_endpoints || (var.enable_nat_gateway == false)
}