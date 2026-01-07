targetScope = 'resourceGroup'

param location string = resourceGroup().location
param projectName string = 'secureweb'
param adminUsername string
@secure()
param adminPassword string

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    projectName: projectName
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    projectName: projectName
    vnetId: network.outputs.vnetId
    snetDataId: network.outputs.snetDataId
  }
}

module compute 'modules/compute.bicep' = {
  name: 'compute'
  params: {
    location: location
    projectName: projectName
    adminUsername: adminUsername
    adminPassword: adminPassword
    snetWebId: network.outputs.snetWebId
    lbFrontendPublicIpId: network.outputs.lbPublicIpId
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    projectName: projectName
    vmssId: compute.outputs.vmssId
  }
}

output loadBalancerPublicIp string = network.outputs.lbPublicIp
output sqlServerName string = sql.outputs.sqlServerName
output sqlDatabaseName string = sql.outputs.sqlDatabaseName
