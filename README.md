# Secure Web App + Azure SQL (Private) + Load Balancer + VMSS Autoscaling (Bicep)

## Overview
This project deploys a secure, scalable web tier behind an Azure Standard Load Balancer with autoscaling, and a private Azure SQL Database accessible only via Private Endpoint.

## Architecture
- VNet: 10.10.0.0/16
- Subnets:
  - snet-web: 10.10.1.0/24 (VMSS)
  - snet-data: 10.10.2.0/24 (Private Endpoint)
  - AzureBastionSubnet: 10.10.10.0/27 (Bastion)
- Public Standard Load Balancer → VMSS (IIS)
- Azure SQL Server: Public access disabled + Private Endpoint + Private DNS
- Autoscale: CPU-based scale out/in rules

## Security Controls
- No public IPs on VM instances (access via Bastion)
- SQL public network access disabled
- Private DNS zone for SQL private link

## Deploy (Azure CLI)
```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"

RG="rg-secure-web-lb-autoscale"
LOC="uksouth"

az group create -n $RG -l $LOC
az deployment group create -n main -g $RG -f infra/main.bicep -p infra/main.parameters.json
