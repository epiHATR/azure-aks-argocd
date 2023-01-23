variable "aks_name" {
  description = "Name of Azure kubernetes service cluster"
  type = string
}

variable "aks_location" {
  type    = string
  default = "northeurope"
  description = "Azure location where AKS cluster locates on"
}

variable "aks_version" {
  type    = string
  default = "1.24.9"
  description = "Kubernetes version, you can select correct version by `az aks versions -l northeurope`"
}

variable "vnet_address_prefix" {
  type = string
  description = "Virtual network address prefix (address space)"
}

variable "aks_subnet_address_prefix" {
  type = string
  description = "AKS address prefix (address ranges) for AKS cluster"
}

variable "cluster_appgw_address_prefix" {
  type = string
  description = "Application gateway address prefix, it should be the last smallest range /27 or /28 in the virtual network address space"
}

variable "argocd_admin_password" {
  type = string
  description = "Administrator password of ArgoCD server"
}
