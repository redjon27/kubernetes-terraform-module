locals {
  tags = merge(
    {
      ManagedBy = "terraform"
      Project   = var.name
    },
    var.tags
  )

  vpc_endpoints_enabled = var.enable_vpc_endpoints || (var.enable_nat_gateway == false)
}