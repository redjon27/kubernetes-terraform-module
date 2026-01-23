locals {
  oidc_provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

resource "aws_iam_role" "irsa" {
  for_each = var.irsa_roles

  name = "${var.name}-irsa-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.serviceaccount}"
        }
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_policy" "irsa" {
  for_each = {
    for k, v in var.irsa_roles : k => v
    if try(v.policy, null) != null && length(try(v.policy.Statement, [])) > 0
  }

  name   = "${var.name}-irsa-${each.key}"
  policy = jsonencode(each.value.policy)
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "irsa_inline" {
  for_each = aws_iam_policy.irsa

  role       = aws_iam_role.irsa[each.key].name
  policy_arn = aws_iam_policy.irsa[each.key].arn
}

locals {
  irsa_managed_attachments = merge([
    for role_key, role_cfg in var.irsa_roles : {
      for policy_arn in try(role_cfg.policy_arns, []) :
      "${role_key}::${policy_arn}" => {
        role_key   = role_key
        policy_arn = policy_arn
      }
    }
  ]...)
}

resource "aws_iam_role_policy_attachment" "irsa_managed" {
  for_each = local.irsa_managed_attachments

  role       = aws_iam_role.irsa[each.value.role_key].name
  policy_arn = each.value.policy_arn
}
