
output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = try(aws_eks_cluster.eks_cluster.arn, "")
}

output "eks_cluster_id" {
value  = aws_eks_cluster.eks_cluster.id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = try(aws_eks_cluster.eks_cluster.endpoint, "")
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

# output "eks_cluster_certificate_authority_data" {
#   description = "Base64 encoded certificate data required to communicate with the cluster"
#   value       = try(aws_eks_cluster.eks_cluster.certificate_authority[0].data, "")
# }

# output "eks_cluster_oidc_issuer_url" {
#   description = "The URL on the EKS cluster for the OpenID Connect identity provider"
#   value       = try(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "")
# }

# output "eks_cluster_version" {
#   description = "The Kubernetes version for the cluster"
#   value       = try(aws_eks_cluster.eks_cluster.version, "")
# }
# output "eks_fargate_profile_status" {
#   description = "The EKS Cluster System fargate profile status where CoreDNS is running"
#   value       = try(aws_eks_fargate_profile.eks_fargate_system.status, "")
# }

# output "eks_cluster_platform_version" {
#   description = "Platform version for the cluster"
#   value       = try(aws_eks_cluster.eks_cluster.platform_version, "")
# }

# output "eks_cluster_primary_security_group_id" {
#   description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
#   value       = try(aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id, "")
# }



# ################################################################################
# # IRSA
# ################################################################################

# output "oidc_provider" {
#   description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
#   value       = try(replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", ""), "")
# }

# output "oidc_provider_arn" {
#   description = "The ARN of the OIDC Provider if `enable_irsa = true`"
#   value       = try(aws_iam_openid_connect_provider.oidc_provider.arn, "")
# }
