locals {
  alb_controller_helm_repo     = "https://aws.github.io/eks-charts"
  alb_controller_chart_name    = "aws-load-balancer-controller"
  alb_controller_chart_version = var.aws_load_balancer_controller_chart_version
  aws_alb_ingress_class        = "alb"
  aws_vpc_id                   = data.aws_vpc.selected.id
  aws_region_name              = data.aws_region.current.name
  aws_iam_path_prefix          = var.aws_iam_path_prefix == "" ? null : var.aws_iam_path_prefix
  service_account_name         = substr("${var.k8s_cluster_name}-aws-load-balancer-controller",0,64)
}

resource "aws_iam_role" "this" {
  name        = substr("${var.aws_resource_name_prefix}${var.k8s_cluster_name}-aws-load-balancer-controller", 0, 64)
  description = "Permissions required by the Kubernetes AWS Load Balancer controller to do its job."
  path        = local.aws_iam_path_prefix

  tags = var.aws_tags

  force_detach_policies = true

  assume_role_policy = var.k8s_cluster_type == "vanilla" ? data.aws_iam_policy_document.ec2_assume_role[0].json : data.aws_iam_policy_document.eks_oidc_assume_role[0].json
}


resource "aws_iam_policy" "this" {
  name        = substr("${var.aws_resource_name_prefix}${var.k8s_cluster_name}-alb-management",0,64)
  description = format("Permissions that are required to manage AWS Application Load Balancers.")
  path        = "/" #local.aws_iam_path_prefix
  # We use a heredoc for the policy JSON so that we can more easily diff and
  # copy/paste from upstream. Ignore whitespace when you diff to more easily see the changes!
  # Source: `curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy.json`
  policy = file("${path.module}/iam_policy.json")
        tags = {
                 Name        = "${var.k8s_cluster_name}-lb_controller-iam"
                }
  }

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "vpc-cni-addon" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       =  aws_iam_role.this.name
}

resource "kubernetes_service_account" "this" {
  automount_service_account_token = true
  metadata {
    name      =  local.service_account_name
    namespace = var.k8s_namespace
    annotations = {
      # This annotation is only used when running on EKS which can
      # use IAM roles for service accounts.
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "helm" # "terraform" #
      "meta.helm.sh/release-name"   = "aws-load-balancer-controller"
      "meta.helm.sh/release-namespace" = var.k8s_namespace
    }
  }
}

resource "kubernetes_cluster_role" "this" {
  metadata {
    name = "aws-load-balancer-controller"

    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "configmaps",
      "endpoints",
      "events",
      "ingresses",
      "ingresses/status",
      "services",
    ]

    verbs = [
      "create",
      "get",
      "list",
      "update",
      "watch",
      "patch",
    ]
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "nodes",
      "pods",
      "secrets",
      "services",
      "namespaces",
    ]

    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
  depends_on = [var.alb_controller_depends_on]
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = "aws-load-balancer-controller"

    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.this.metadata[0].name
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata[0].name
    namespace = kubernetes_service_account.this.metadata[0].namespace
  }
}
#
#resource "helm_release" "alb_controller" {
#
#  name       = "aws-load-balancer-controller"
#  repository = local.alb_controller_helm_repo
#  chart      = local.alb_controller_chart_name
#  version    = local.alb_controller_chart_version
#  namespace  = var.k8s_namespace
#  atomic     = true
#  timeout    = 900
#
#  dynamic "set" {
#
#    for_each = {
#      "clusterName"           = var.k8s_cluster_name
#      "serviceAccount.create" = (var.k8s_cluster_type != "eks")
#      "serviceAccount.name"   = (var.k8s_cluster_type == "eks") ? kubernetes_service_account.this.metadata[0].name : null
#      "region"                = local.aws_region_name
#      "vpcId"                 = local.aws_vpc_id
#      "hostNetwork"           = var.enable_host_networking
#    }
#    content {
#      name  = set.key
#      value = set.value
#    }
#  }
#
#  dynamic "set" {
#    for_each = var.chart_env_overrides
#    content {
#      name  = set.key
#      value = set.value
#    }
#  }
#
#  depends_on = [var.alb_controller_depends_on]
#}
#
#resource "helm_release" "loadbalancer_controller" {
#  depends_on = [aws_iam_role.this]
#  name       = "aws-load-balancer-controller"
#
#  repository = "https://aws.github.io/eks-charts"
#  chart      = "aws-load-balancer-controller"
#
#  namespace = "kube-system"
#
#  # Value changes based on your Region (Below is for us-east-1)
#  set {
#    name = "image.repository"
#    value = "602401143452.dkr.ecr.eu-central-1.amazonaws.com/amazon/aws-load-balancer-controller"
#    # Changes based on Region - This is for us-east-1 Additional Reference: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
#  }
#
#  set {
#    name  = "serviceAccount.create"
#    value = "true"
#  }
#
#  set {
#    name  = "serviceAccount.name"
#    value = "aws-load-balancer-controller"
#  }
#
#  set {
#    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#    value = "${aws_iam_role.this.arn}"
#  }
#
#  set {
#    name  = "vpcId"
#    value = local.aws_vpc_id
#  }
#
#  set {
#    name  = "region"
#    value = local.aws_region_name
#  }
#
#  set {
#    name  = "clusterName"
#    value = var.k8s_cluster_name
#  }
#
#}

resource "helm_release" "alb_controller" {

  name       = "aws-load-balancer-controller"
  repository = local.alb_controller_helm_repo
  chart      = local.alb_controller_chart_name
  version    = local.alb_controller_chart_version
  namespace  = var.k8s_namespace
  create_namespace = false
  atomic     = true
  timeout    = 900
  cleanup_on_fail = true

  set {
      name = "clusterName"
      value = var.k8s_cluster_name
      type = "string"
  }
  set {
      name = "serviceAccount.create"
      value = "false"
      type = "auto"
  }
  set {
      name = "serviceAccount.name"
      value = kubernetes_service_account.this.metadata[0].name
      type = "string"
  }
  set {
      name = "region"
      value = local.aws_region_name
      type = "string"
  }
  set {
      name = "vpcId"
      value = local.aws_vpc_id
      type = "string"
  }
  set {
      name =  "hostNetwork"
      value =   var.enable_host_networking
      type = "auto"
  }
}