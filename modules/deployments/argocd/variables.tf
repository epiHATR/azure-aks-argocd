variable "namespace" {
  type    = string
  default = "argocd"
}

variable "release_name" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  type    = string
  default = "5.13.6"
}

variable "chart_name" {
  type    = string
  default = "argo-cd"
}

variable "release_repo" {
  type    = string
  default = "https://argoproj.github.io/argo-helm"
}

variable "argocd_admin_password" {
  type = string
}