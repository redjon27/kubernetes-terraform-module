output "cluster_name" {
  value = module.platform.cluster_name
}

output "cluster_endpoint" {
  value = module.platform.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  value = module.platform.cluster_oidc_issuer_url
}

output "irsa_role_arns" {
  description = "IRSA role ARNs created by eks-platform module"
  value       = module.platform.irsa_role_arns
}