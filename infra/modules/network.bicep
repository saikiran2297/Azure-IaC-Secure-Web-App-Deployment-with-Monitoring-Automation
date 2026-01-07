param location string
param projectName string

var vnetName = 'vnet-${projectName}'
var lbPipName = 'pip-lb-${projectName}'
var bastionPipName = 'pip-bastion-${projectName}'

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: [ '10.10.0.0/16' ] }
    subnets: [
      {
        name: 'snet-web'
        properties: { addressPrefix: '10.10.1.0/24' }
      }
      {
        name: 'snet-data'
        properties: { addressPrefix: '10.10.2.0/24' }
      }
      {
        name: 'AzureBastionSubnet'
        properties: { addressPrefix: '10.10.10.0/27' }
      }
    ]
  }
}

resource lbPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: lbPipName
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: bastionPipName
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: 'bas-${projectName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipcfg'
        properties: {
          subnet: { id: '${vnet.id}/subnets/AzureBastionSubnet' }
          publicIPAddress: { id: bastionPip.id }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output snetWebId string = '${vnet.id}/subnets/snet-web'
output snetDataId string = '${vnet.id}/subnets/snet-data'

output lbPublicIpId string = lbPip.id
output lbPublicIp string = lbPip.properties.ipAddress
