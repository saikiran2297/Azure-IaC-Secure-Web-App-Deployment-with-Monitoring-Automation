param location string
param projectName string

var vnetName = '${projectName}-vnet'
var webSubnetName = 'snet-web'
var dataSubnetName = 'snet-data'
var bastionSubnetName = 'AzureBastionSubnet' // must be exact

// Load balancer names as vars to avoid self-reference issues
var lbName = '${projectName}-lb'
var feName = 'fe'
var beName = 'be'
var probeName = 'http-probe'

// NSGs
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${projectName}-nsg-web'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-In'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Deny-All-In'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgData 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${projectName}-nsg-data'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Deny-All-In'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// VNet + subnets
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: webSubnetName
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: { id: nsgWeb.id }
        }
      }
      {
        name: dataSubnetName
        properties: {
          addressPrefix: '10.10.2.0/24'
          // required for Private Endpoints
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: { id: nsgData.id }
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: '10.10.10.0/27'
        }
      }
    ]
  }
}

// Public IP for LB
resource lbPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${projectName}-lb-pip'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Load Balancer
resource lb 'Microsoft.Network/loadBalancers@2023-11-01' = {
  name: lbName
  location: location
  sku: { name: 'Standard' }
  properties: {
    frontendIPConfigurations: [
      {
        name: feName
        properties: {
          publicIPAddress: { id: lbPip.id }
        }
      }
    ]
    backendAddressPools: [
      { name: beName }
    ]
    probes: [
      {
        name: probeName
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'http-80'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, feName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, beName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, probeName)
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 4
          enableFloatingIP: false
        }
      }
    ]
  }
}

// Bastion Public IP + Bastion
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${projectName}-bastion-pip'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: '${projectName}-bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, bastionSubnetName)
          }
          publicIPAddress: { id: bastionPip.id }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output snetWebId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, webSubnetName)
output snetDataId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, dataSubnetName)

output lbId string = lb.id
output lbBackendPoolId string = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, beName)
output lbPublicIpId string = lbPip.id
output lbPublicIpAddress string = lbPip.properties.ipAddress

output bastionName string = bastion.name
