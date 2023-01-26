# DEPLOY ARGOCD SERVER
locals {
  values = {
    server = {
      ingress = {
        enabled = true
        annotations = {
          "kubernetes.io/ingress.class"                  = "azure/application-gateway"
          "appgw.ingress.kubernetes.io/backend-protocol" = "http"
          "appgw.ingress.kubernetes.io/request-timeout"  = "300"
        }
        hosts = []
      }
    }
  }
}

resource "helm_release" "argocd" {
  name             = var.release_name
  repository       = var.release_repo
  chart            = var.chart_name
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode(local.values)]

  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(var.argocd_admin_password)
  }
}
