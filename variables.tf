variable "aks_name" {
  type = string
}

variable "aks_location" {
  type    = string
  default = "northeurope"
}

variable "aks_version" {
  type    = string
  default = "1.24.9"
}

variable "vnet_address_prefix" {
  type = string
}

variable "aks_subnet_address_prefix" {
  type = string
}

variable "cluster_appgw_address_prefix" {
  type = string
}

variable "argocd_admin_password" {
  type = string
}
