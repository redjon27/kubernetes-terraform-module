locals {
  tags = merge(
    {
      ManagedBy = "terraform"
      Project   = var.name
    },
    var.tags
  )
}
