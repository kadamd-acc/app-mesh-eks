# data "aws_db_instance" "database" {
#  db_instance_identifier = "${var.identifier}-${var.environment}"
# }

# data "kubernetes_ingress" "address" {
#  metadata {
#    name = "owncloud-lb"
#    namespace = "fargate-node"
#  }
# }

# output "database_endpoint" {
#    value = "${data.aws_db_instance.database.address}"
# }

# output "server_dns" {
#    value = "${data.kubernetes_ingress.address.load_balancer_ingress}"
# }

output "cluster_name" {
  value = module.eks.eks_cluster_name
}

# output "certificate_arn" {
#   value = module.acm.acm_certificate_arn
# }

# output "validation_record" {
#   value = module.acm.acm_certificate_dns_validation_record
# }