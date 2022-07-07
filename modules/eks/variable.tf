variable "cluster_name" {
  description = "the name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}


variable "private_subnets" {
  type = list(string)
  description = "List of private subnet IDs"
}

variable "public_subnets" {
  description = "List of private subnet IDs"
}

variable "fargate_app_namespace" {
  description = "Name of fargate selector namespace"
}


variable "cluster_version" {
  description = "Version of the EKS Cluster"
  default = "1.22"
}

variable "namespace" {
    type = string
  }
variable "workload" {
    type = string
  }
variable "region_name" {
  type = string
  }