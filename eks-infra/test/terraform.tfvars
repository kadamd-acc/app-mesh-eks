# EKS Cluster and Network Infrastructure

environment                  =  "testing"
namespace                    = "plat-6521"
workload                     = "eksplat"
user_profile                 =  "AWS_741032333307_User"
user_os                      =  "linux"
cluster_name                 =  "landg-eks-clstr"
cluster_version              =  "1.22"
cluster_type                 =  "eks"
cluster_group                =  "eks-fargate"
vpc_cidr                     =  "192.168.0.0/16"
vpc_name                     =  "eks-vpc"
public_subnets_cidr          =  ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"]
private_subnets_cidr         =  ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
region_name                  =  "eu-west-1"
availability_zones_public    =  ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
availability_zones_private   =  ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
cidr_block_internet_gw       =  "0.0.0.0/0"
cidr_block_nat_gw            =  "0.0.0.0/0"
fargate_app_namespace        =  ["ns-fargate-app", "ns-fargate-app2"]


