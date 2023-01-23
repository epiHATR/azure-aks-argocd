# Introduction
This is Terraform template which creates an AKS cluster with ArgoCD installed and accessible though a public IP address

# Features
This Terraform template will provision following resource on Azure:
- Azure AKS cluster
- Azure Application Gateway
- Azure Public IP address for ingress and egress
- ArgoCD server accessible via ingress Domain Name label (...cloudapp.azure.com)

# Getting Started
You can choose one of following method to apply Terraform template to your Azure environments:
- Run locally with ```terraform cli```
- Using Terraform cloud

## Run Terraform template locally
#### Prepare parameters and variables
After clone this repository to your local machine, you can now edit file ```parameter.tfvars``` with your setup
```yaml
aks_name                     = "hatr-aks"
aks_location                 = "northeurope"
aks_version                  = "1.25.4"
vnet_address_prefix          = "10.80.0.0/16"
aks_subnet_address_prefix    = "10.80.0.0/24"
cluster_appgw_address_prefix = "10.80.255.224/27"
argocd_admin_password        = "<change this value>"
```
#### Apply Terraform template
##### 1. Authenticate against Azure
You can using Azure CLI (az module) to help Terraform authenticates againts Azure by 
```bash
az login --tenant <your tenant ID>
az account set --subscription <your Azure subscription ID>
```
Or
You can also authenticate with Azure RM with service principal in Terraform by
```bash
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

##### 2. Run Terraform init & plan
Run following commands to initilize Terraform providers and plan your changes
```bash
terraform init
terraform plan -var-file=parameter.tfvars
```

##### 3. Run Terraform apply
Run ```apply``` command to create configured resources
```bash
terraform apply -var-file=parameter.tfvars
```

## Using Terraform Cloud
Follow this article to apply above [Terraform template using Terraform Cloud](https://cloudcli.io)