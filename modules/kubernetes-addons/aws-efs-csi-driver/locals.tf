locals {
  name                   = "aws-efs-csi-driver"
  namespace              = "kube-system"
  service_account        = try(var.helm_config.service_account, "efs-csi-sa")
  create_service_account = try(var.helm_config.create_service_account, true)

  default_helm_config = {
    name        = local.name
    chart       = local.name
    repository  = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
    version     = "2.2.6"
    namespace   = local.namespace
    values      = []
    description = "The AWS EFS CSI driver Helm chart deployment configuration"
  }

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )

  set_values = [
    {
      name  = "controller.serviceAccount.name"
      value = local.service_account
    },
    {
      name  = "controller.serviceAccount.create"
      value = false
    },
    {
      name  = "node.serviceAccount.name"
      value = local.service_account
    },
    {
      name  = "node.serviceAccount.create"
      value = false
    }
  ]

  irsa_config = {
    kubernetes_namespace              = local.helm_config["namespace"]
    kubernetes_service_account        = local.service_account
    create_kubernetes_namespace       = false
    create_kubernetes_service_account = local.create_service_account
    irsa_iam_policies                 = concat([aws_iam_policy.aws_efs_csi_driver.arn], var.irsa_policies)
    tags                              = var.addon_context.tags
  }

  argocd_gitops_config = {
    enable             = true
    serviceAccountName = local.service_account
  }
}
