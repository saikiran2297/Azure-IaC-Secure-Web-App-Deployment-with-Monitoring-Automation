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
          destinat


