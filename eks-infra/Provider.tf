
provider "aws" {
  region     = var.region_name
  default_tags {
    tags={
      "landg:cost-center" = "C123456"
      "landg:business-unit" = "group-technology"
      "landg:business-name" = "eks"
      "landg:environment-type" = "test"           
    }
  }
}
terraform {
  backend "s3" {
    bucket = "landg-terraform-state"
    key    = "landg-terraform/test/terraform.tfstate"
    region = "eu-west-2"
    encrypt= true

  }
  }
locals {
  cluster_name= data.aws_eks_cluster.eks_cluster.name
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  #config_path = "./.kube/config"
  config_path ="${var.github_runner_base_path}.kube/config"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    #config_path = "./.kube/config"
    config_path ="${var.github_runner_base_path}.kube/config"
  }
}


##
#provider "helm" {
#  kubernetes {
#    host                   = data.aws_eks_cluster.eks_cluster.endpoint
#    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#    exec {
#      api_version = "client.authentication.k8s.io/v1alpha1"
#      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
#      command     = "aws"
#    }
#  }
#}

#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.eks_cluster.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#  exec {
#    api_version = "client.authentication.k8s.io/v1alpha1"
#    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
#    command     = "aws"
#  }
#}
