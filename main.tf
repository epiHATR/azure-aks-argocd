terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.16.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.7.1"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.34.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  rg_name     = var.aks_name
  rg_location = var.aks_location

  #virtual network
  vnet_name           = var.aks_name
  vnet_address_prefix = var.vnet_address_prefix

  #subnet
  subnet_name           = var.aks_name
  subnet_address_prefix = var.aks_subnet_address_prefix

  #ingress PIP
  ingress_pip_name = "${var.aks_name}-ingress"
  ingress_dn_label = "${var.aks_name}-ingress-dnl"

  #egress PIP
  egress_pip_name = "${var.aks_name}-egress"

  #appGateway
  app_gateway_name               = "${var.aks_name}-appgw"
  gateway_ip_configuration_name  = "default"
  cluster_appgateway_subnet_name = "${var.aks_name}-appgw"
  cluster_appgw_address_prefix   = var.cluster_appgw_address_prefix
  frontend_ip_configuration_name = "default"
  backend_http_setting_name      = "default"
  backend_address_pool_name      = "default"
  frontend_port_name             = "default"
  http_listener_name             = "default"
  request_routing_rule_name      = "default"

  #aks
  aks_name            = var.aks_name
  aks_version         = var.aks_version
  cluster_aks_rg_name = "${var.aks_name}-k8s-rg"
  dns_prefix          = var.aks_name
  node_pool           = "default"

  #argocd
  argocd_admin_password = var.argocd_admin_password

}

resource "azurerm_resource_group" "group" {
  name     = local.rg_name
  location = local.rg_location
}

# CREATE VNET
resource "azurerm_virtual_network" "vnet" {
  resource_group_name = local.rg_name
  location            = local.rg_location
  name                = local.vnet_name
  address_space       = [local.vnet_address_prefix]

  depends_on = [
    azurerm_resource_group.group
  ]
}

# CREATE SUBNET FOR CLUSTER
resource "azurerm_subnet" "cluster_subnet" {
  name                 = local.subnet_name
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.subnet_address_prefix]

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# CREATE SUBNET FOR APPLICATION GATEWAY
resource "azurerm_subnet" "gateway_subnet" {
  name                 = local.cluster_appgateway_subnet_name
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.cluster_appgw_address_prefix]

  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_subnet.cluster_subnet
  ]
}

# CREATE INGRESS PUBLIC IP FOR CLUSTER
resource "azurerm_public_ip" "ingress_pip" {
  name                = local.ingress_pip_name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  domain_name_label   = local.ingress_dn_label

  depends_on = [
    azurerm_resource_group.group
  ]
}

# CREATE EGRESS PUBLIC IP FOR CLUSTER
resource "azurerm_public_ip" "egress_pip" {
  name                = local.egress_pip_name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"

  depends_on = [
    azurerm_resource_group.group
  ]
}

# CREATE APPLICATION GATEWAY
resource "azurerm_application_gateway" "app_gateway" {
  name                = local.app_gateway_name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = azurerm_subnet.gateway_subnet.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.ingress_pip.id
  }

  backend_http_settings {
    name                  = local.backend_http_setting_name
    cookie_based_affinity = "Enabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 300
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_setting_name
    priority                   = 100
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_ip_configuration,
      frontend_port,
      http_listener,
      probe,
      request_routing_rule,
      tags
    ]
  }

  depends_on = [
    azurerm_public_ip.ingress_pip,
    azurerm_subnet.gateway_subnet
  ]
}

# CREATE AZURE KUBERNETES SERVICES
resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  dns_prefix          = local.dns_prefix
  kubernetes_version  = local.aks_version
  node_resource_group = local.cluster_aks_rg_name

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    load_balancer_profile {
      outbound_ip_address_ids = [azurerm_public_ip.egress_pip.id]
    }
  }

  default_node_pool {
    name           = local.node_pool
    node_count     = 3
    vm_size        = "Standard_D2_v2"
    os_sku         = "Ubuntu"
    vnet_subnet_id = azurerm_subnet.cluster_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.app_gateway.id
  }

  depends_on = [
    azurerm_resource_group.group,
    azurerm_public_ip.egress_pip,
    azurerm_subnet.cluster_subnet,
    azurerm_application_gateway.app_gateway
  ]
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

#CREATE ROLE ASSIGNMENT FOR THE APP GATEWAY
resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = azurerm_application_gateway.app_gateway.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_kubernetes_cluster.cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

  depends_on = [
    time_sleep.wait_60_seconds,
    data.azurerm_kubernetes_cluster.cluster
  ]
}

#CREATE ROLE ASSIGNMENT TO THE RESOURCE GROUP
resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = azurerm_resource_group.group.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_kubernetes_cluster.cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

  depends_on = [
    time_sleep.wait_60_seconds,
    data.azurerm_kubernetes_cluster.cluster
  ]
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

# DEPLOY ARGOCD
module "argocd" {
  source                = "./modules/deployments/argocd"
  argocd_admin_password = local.argocd_admin_password
}
