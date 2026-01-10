# Secure Web App + Azure SQL (Private) with Load Balancer + VMSS Autoscaling (Bicep)

This project deploys:
- VNet with subnets:
  - snet-web: 10.10.1.0/24
  - snet-data: 10.10.2.0/24
  - AzureBastionSubnet: 10.10.10.0/27
- Standard Public Load Balancer (HTTP/80)
- Windows VM Scale Set (IIS) behind the LB + autoscale rules
- Azure SQL Server + DB with Public Access Disabled
- SQL Private Endpoint in snet-data + Private DNS Zone link
- Azure Bastion for secure admin access (no public RDP)
- Log Analytics workspace + VM monitoring agent

## Architecture (Mermaid)
```mermaid
flowchart LR
  Internet((Internet)) --> LB[Public Load Balancer :80]
  LB --> VMSS[VM Scale Set (IIS)]
  VMSS -->|Private DNS| SQL[(Azure SQL Database)]
  VMSS --- VNET[VNet 10.10.0.0/16]
  VNET --> WEB[snet-web 10.10.1.0/24]
  VNET --> DATA[snet-data 10.10.2.0/24]
  VNET --> BAS[AzureBastionSubnet 10.10.10.0/27]
  Bastion[Azure Bastion] --> VMSS
