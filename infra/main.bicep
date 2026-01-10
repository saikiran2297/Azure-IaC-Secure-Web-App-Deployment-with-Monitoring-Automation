targetScope = 'resourceGroup'

param location string = resourceGroup().location
param projectName string = 'secureweb'

param adminUsername string
@secure()
param adminPassword string

param sqlAdminUsername string = adminUsername
@secure()
param sqlAdminPassword string = adminPassword

param vmSku string = 'Standard_DS2_v2'
param instanceCount int = 2

module network 'modules/network.bicep' = {
  name: '${projectName}-network'
  params: {
    location: location
    projectName: projectName
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: '${projectName}-monitoring'
  params: {
    location: location
    projectName: projectName
  }
}

module sql 'modules/sql.bicep' = {
  name: '${projectName}-sql'
  params: {
    location: location
    projectName: projectName
    sqlAdminUsername: sqlAdminUsername
    sqlAdminPassword: sqlAdminPassword

    vnetId: network.outputs.vnetId
    snetDataId: network.outputs.snetDataId
  }
}

module compute 'modules/compute.bicep' = {
  name: '${projectName}-compute'
  params: {
    location: location
    projectName: projectName

    adminUsername: adminUsername
    adminPassword: adminPassword

    vmSku: vmSku
    instanceCount: instanceCount

    snetWebId: network.outputs.snetWebId

    logAnalyticsWorkspaceCustomerId: monitoring.outputs.workspaceCustomerId
    logAnalyticsWorkspaceKey: monitoring.outputs.workspaceSharedKey

    sqlPrivateFqdn: sql.outputs.sqlPrivateFqdn
  }
}

output websitePublicIp string = network.outputs.lbPublicIpAddress
output sqlServerName string = sql.outputs.sqlServerName
output sqlDatabaseName string = sql.outputs.sqlDatabaseName
output bastionName string = network.outputs.bastionName

